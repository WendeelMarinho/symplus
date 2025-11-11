<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\SubscriptionResource;
use App\Models\Organization;
use App\Models\Subscription;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Stripe\Exception\ApiErrorException;
use Stripe\StripeClient;

class SubscriptionController extends Controller
{
    protected ?StripeClient $stripe = null;

    /**
     * Get Stripe client instance (lazy initialization).
     */
    protected function getStripe(): ?StripeClient
    {
        if ($this->stripe === null && config('services.stripe.secret')) {
            $this->stripe = new StripeClient(config('services.stripe.secret'));
        }

        return $this->stripe;
    }

    /**
     * Get the current organization's subscription.
     */
    public function show(Request $request): JsonResponse
    {
        $organizationId = $request->header('X-Organization-Id');
        $organization = Organization::findOrFail($organizationId);

        $subscription = $organization->subscription;

        if (! $subscription) {
            // Criar subscription gratuita se não existir
            $subscription = Subscription::create([
                'organization_id' => $organizationId,
                'plan' => 'free',
                'status' => 'active',
            ]);
        }

        return (new SubscriptionResource($subscription->load('organization')))
            ->response()
            ->setStatusCode(200);
    }

    /**
     * Create or update subscription (Stripe integration).
     */
    public function update(Request $request): JsonResponse
    {
        $request->validate([
            'plan' => ['required', 'in:free,basic,premium,enterprise'],
            'payment_method_id' => ['required_if:plan,free,false', 'string'],
        ]);

        $organizationId = $request->header('X-Organization-Id');
        $organization = Organization::findOrFail($organizationId);
        $plan = $request->input('plan');

        // Se for free, apenas atualizar
        if ($plan === 'free') {
            $subscription = $organization->subscription;
            if ($subscription) {
                // Cancelar subscription no Stripe se existir
                if ($subscription->stripe_subscription_id && $this->getStripe()) {
                    try {
                        $this->getStripe()->subscriptions->cancel($subscription->stripe_subscription_id);
                    } catch (ApiErrorException $e) {
                        Log::warning('Failed to cancel Stripe subscription', [
                            'subscription_id' => $subscription->stripe_subscription_id,
                            'error' => $e->getMessage(),
                        ]);
                    }
                }
                $subscription->update([
                    'plan' => 'free',
                    'status' => 'active',
                    'stripe_subscription_id' => null,
                    'stripe_customer_id' => null,
                ]);
            } else {
                $subscription = Subscription::create([
                    'organization_id' => $organizationId,
                    'plan' => 'free',
                    'status' => 'active',
                ]);
            }

            return (new SubscriptionResource($subscription))->response();
        }

        // Para planos pagos, criar/atualizar no Stripe
        // Se Stripe não estiver configurado, retornar erro
        if (! $this->getStripe()) {
            return response()->json([
                'message' => 'Stripe is not configured. Please set STRIPE_SECRET in your environment.',
            ], 500);
        }

        try {
            $subscription = $organization->subscription;

            if ($subscription && $subscription->stripe_customer_id) {
                // Atualizar subscription existente
                if ($subscription->stripe_subscription_id) {
                    $stripeSubscription = $this->getStripe()->subscriptions->retrieve($subscription->stripe_subscription_id);

                    // Atualizar plano no Stripe
                    $this->getStripe()->subscriptions->update($subscription->stripe_subscription_id, [
                        'items' => [[
                            'id' => $stripeSubscription->items->data[0]->id,
                            'price' => $this->getStripePriceId($plan),
                        ]],
                    ]);

                    $subscription->update([
                        'plan' => $plan,
                        'status' => 'active',
                    ]);
                } else {
                    // Criar nova subscription no Stripe
                    $this->createStripeSubscription($organization, $subscription, $plan, $request->input('payment_method_id'));
                }
            } else {
                // Criar customer e subscription no Stripe
                $customer = $this->getStripe()->customers->create([
                    'email' => $organization->users()->first()?->email,
                    'metadata' => ['organization_id' => $organizationId],
                ]);

                $subscription = Subscription::create([
                    'organization_id' => $organizationId,
                    'stripe_customer_id' => $customer->id,
                    'plan' => $plan,
                    'status' => 'trialing',
                    'trial_ends_at' => now()->addDays(14),
                ]);

                $this->createStripeSubscription($organization, $subscription, $plan, $request->input('payment_method_id'));
            }

            return (new SubscriptionResource($subscription->fresh()))->response();
        } catch (ApiErrorException $e) {
            Log::error('Stripe API error', ['error' => $e->getMessage()]);

            return response()->json([
                'message' => 'Failed to process subscription',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Cancel subscription.
     */
    public function cancel(Request $request): JsonResponse
    {
        $organizationId = $request->header('X-Organization-Id');
        $organization = Organization::findOrFail($organizationId);
        $subscription = $organization->subscription;

        if (! $subscription || $subscription->plan === 'free') {
            return response()->json(['message' => 'No active subscription to cancel'], 400);
        }

        try {
            if ($subscription->stripe_subscription_id && $this->getStripe()) {
                // Cancelar no final do período (não imediato)
                $this->getStripe()->subscriptions->update($subscription->stripe_subscription_id, [
                    'cancel_at_period_end' => true,
                ]);
            }

            $subscription->update([
                'ends_at' => now()->addMonth(), // Cancelar no final do mês
            ]);

            return (new SubscriptionResource($subscription->fresh()))->response();
        } catch (ApiErrorException $e) {
            Log::error('Stripe cancellation error', ['error' => $e->getMessage()]);

            return response()->json([
                'message' => 'Failed to cancel subscription',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get Stripe price ID for a plan.
     */
    protected function getStripePriceId(string $plan): string
    {
        return match ($plan) {
            'basic' => config('services.stripe.price_basic', 'price_basic'),
            'premium' => config('services.stripe.price_premium', 'price_premium'),
            'enterprise' => config('services.stripe.price_enterprise', 'price_enterprise'),
            default => throw new \InvalidArgumentException("Invalid plan: {$plan}"),
        };
    }

    /**
     * Create Stripe subscription.
     */
    protected function createStripeSubscription(
        Organization $organization,
        Subscription $subscription,
        string $plan,
        string $paymentMethodId
    ): void {
        $stripe = $this->getStripe();

        if (! $stripe) {
            throw new \RuntimeException('Stripe is not configured');
        }

        // Anexar payment method ao customer
        $stripe->paymentMethods->attach($paymentMethodId, [
            'customer' => $subscription->stripe_customer_id,
        ]);

        // Definir como payment method padrão
        $stripe->customers->update($subscription->stripe_customer_id, [
            'invoice_settings' => [
                'default_payment_method' => $paymentMethodId,
            ],
        ]);

        // Criar subscription
        $stripeSubscription = $stripe->subscriptions->create([
            'customer' => $subscription->stripe_customer_id,
            'items' => [['price' => $this->getStripePriceId($plan)]],
            'trial_period_days' => 14,
            'payment_behavior' => 'default_incomplete',
            'expand' => ['latest_invoice.payment_intent'],
        ]);

        $subscription->update([
            'stripe_subscription_id' => $stripeSubscription->id,
            'status' => $stripeSubscription->status,
            'trial_ends_at' => $stripeSubscription->trial_end ? now()->setTimestamp($stripeSubscription->trial_end) : null,
        ]);
    }

    /**
     * Webhook handler for Stripe events.
     */
    public function webhook(Request $request): JsonResponse
    {
        $payload = $request->getContent();
        $sigHeader = $request->header('Stripe-Signature');
        $endpointSecret = config('services.stripe.webhook_secret');

        if (! $endpointSecret) {
            return response()->json(['error' => 'Webhook secret not configured'], 500);
        }

        try {
            $event = \Stripe\Webhook::constructEvent($payload, $sigHeader, $endpointSecret);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Invalid signature'], 400);
        }

        // Processar eventos do Stripe
        switch ($event->type) {
            case 'customer.subscription.updated':
            case 'customer.subscription.deleted':
                $stripeSubscription = $event->data->object;
                $subscription = Subscription::where('stripe_subscription_id', $stripeSubscription->id)->first();

                if ($subscription) {
                    $subscription->update([
                        'status' => $stripeSubscription->status,
                        'ends_at' => $stripeSubscription->cancel_at ? now()->setTimestamp($stripeSubscription->cancel_at) : null,
                    ]);
                }
                break;

            case 'invoice.payment_succeeded':
                // Subscription foi paga com sucesso
                break;

            case 'invoice.payment_failed':
                // Falha no pagamento
                $invoice = $event->data->object;
                $subscription = Subscription::where('stripe_customer_id', $invoice->customer)->first();

                if ($subscription) {
                    $subscription->update(['status' => 'past_due']);
                }
                break;
        }

        return response()->json(['status' => 'success']);
    }
}
