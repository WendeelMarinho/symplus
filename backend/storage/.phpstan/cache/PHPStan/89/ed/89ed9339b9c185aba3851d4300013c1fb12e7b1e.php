<?php declare(strict_types = 1);

// odsl-/var/www/html/app
return \PHPStan\Cache\CacheItem::__set_state(array(
   'variableKey' => 'v1',
   'data' => 
  array (
    '/var/www/html/app/Models/Category.php' => 
    array (
      0 => '4dcd0bd09c39edea0047d4bdae3bb799494fab8e',
      1 => 
      array (
        0 => 'app\\models\\category',
      ),
      2 => 
      array (
        0 => 'app\\models\\organization',
        1 => 'app\\models\\transactions',
        2 => 'app\\models\\newfactory',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Models/Subscription.php' => 
    array (
      0 => 'c6dd086e6adf1a299e025e95b42e76229f8de9ab',
      1 => 
      array (
        0 => 'app\\models\\subscription',
      ),
      2 => 
      array (
        0 => 'app\\models\\casts',
        1 => 'app\\models\\organization',
        2 => 'app\\models\\isactive',
        3 => 'app\\models\\isontrial',
        4 => 'app\\models\\iscanceled',
        5 => 'app\\models\\getplanlimits',
        6 => 'app\\models\\canusefeature',
        7 => 'app\\models\\newfactory',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Models/Transaction.php' => 
    array (
      0 => '40207b286532d1ca9cdcc2d1e8fb506e134d6e7f',
      1 => 
      array (
        0 => 'app\\models\\transaction',
      ),
      2 => 
      array (
        0 => 'app\\models\\casts',
        1 => 'app\\models\\organization',
        2 => 'app\\models\\account',
        3 => 'app\\models\\category',
        4 => 'app\\models\\newfactory',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Models/Organization.php' => 
    array (
      0 => '35ebf3b018ad3d61c588276ef32cd31be2f9d888',
      1 => 
      array (
        0 => 'app\\models\\organization',
      ),
      2 => 
      array (
        0 => 'app\\models\\users',
        1 => 'app\\models\\owners',
        2 => 'app\\models\\admins',
        3 => 'app\\models\\accounts',
        4 => 'app\\models\\transactions',
        5 => 'app\\models\\documents',
        6 => 'app\\models\\subscription',
        7 => 'app\\models\\getcurrentplan',
        8 => 'app\\models\\canusefeature',
        9 => 'app\\models\\getfeaturelimit',
        10 => 'app\\models\\newfactory',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Models/User.php' => 
    array (
      0 => '6867099fd73bc555c6c8296402ed20c4bf3ae245',
      1 => 
      array (
        0 => 'app\\models\\user',
      ),
      2 => 
      array (
        0 => 'app\\models\\casts',
        1 => 'app\\models\\organizations',
        2 => 'app\\models\\belongstoorganization',
        3 => 'app\\models\\roleinorganization',
        4 => 'app\\models\\newfactory',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Models/Document.php' => 
    array (
      0 => '6c2c4636311d7fa05d1a027768306f7cdcd0918c',
      1 => 
      array (
        0 => 'app\\models\\document',
      ),
      2 => 
      array (
        0 => 'app\\models\\casts',
        1 => 'app\\models\\organization',
        2 => 'app\\models\\documentable',
        3 => 'app\\models\\geturlattribute',
        4 => 'app\\models\\gettemporaryurl',
        5 => 'app\\models\\exists',
        6 => 'app\\models\\getcontent',
        7 => 'app\\models\\boot',
        8 => 'app\\models\\newfactory',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Models/DueItem.php' => 
    array (
      0 => '377f9695c7fc9906a09c406b1e2a3dc35881dafa',
      1 => 
      array (
        0 => 'app\\models\\dueitem',
      ),
      2 => 
      array (
        0 => 'app\\models\\casts',
        1 => 'app\\models\\organization',
        2 => 'app\\models\\scopepending',
        3 => 'app\\models\\scopeoverdue',
        4 => 'app\\models\\scopepaid',
        5 => 'app\\models\\markaspaid',
        6 => 'app\\models\\isoverdue',
        7 => 'app\\models\\boot',
        8 => 'app\\models\\newfactory',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Models/Notification.php' => 
    array (
      0 => '0b0838a19ee6213b6b356d852ff8eb374808c74c',
      1 => 
      array (
        0 => 'app\\models\\notification',
      ),
      2 => 
      array (
        0 => 'app\\models\\casts',
        1 => 'app\\models\\user',
        2 => 'app\\models\\organization',
        3 => 'app\\models\\markasread',
        4 => 'app\\models\\isunread',
        5 => 'app\\models\\newfactory',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Models/ServiceRequestComment.php' => 
    array (
      0 => '597b70d500d17b0776ff942007b5595338a5a822',
      1 => 
      array (
        0 => 'app\\models\\servicerequestcomment',
      ),
      2 => 
      array (
        0 => 'app\\models\\casts',
        1 => 'app\\models\\servicerequest',
        2 => 'app\\models\\user',
        3 => 'app\\models\\newfactory',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Models/ServiceRequest.php' => 
    array (
      0 => '4f056d0a5505dddb11852df789b98b77180f6028',
      1 => 
      array (
        0 => 'app\\models\\servicerequest',
      ),
      2 => 
      array (
        0 => 'app\\models\\casts',
        1 => 'app\\models\\organization',
        2 => 'app\\models\\creator',
        3 => 'app\\models\\assignee',
        4 => 'app\\models\\comments',
        5 => 'app\\models\\scopeopen',
        6 => 'app\\models\\scopeinprogress',
        7 => 'app\\models\\scoperesolved',
        8 => 'app\\models\\scopeclosed',
        9 => 'app\\models\\markasinprogress',
        10 => 'app\\models\\markasresolved',
        11 => 'app\\models\\markasclosed',
        12 => 'app\\models\\isopen',
        13 => 'app\\models\\newfactory',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Models/PlanLimit.php' => 
    array (
      0 => '7d5457b4b5a48766fef3bb8877f85629f5d4ee2d',
      1 => 
      array (
        0 => 'app\\models\\planlimit',
      ),
      2 => 
      array (
        0 => 'app\\models\\casts',
        1 => 'app\\models\\seeddefaultlimits',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Models/Account.php' => 
    array (
      0 => '0f30b1294bd1f5d3adbb470ff5c96004e7cde032',
      1 => 
      array (
        0 => 'app\\models\\account',
      ),
      2 => 
      array (
        0 => 'app\\models\\casts',
        1 => 'app\\models\\organization',
        2 => 'app\\models\\transactions',
        3 => 'app\\models\\getcurrentbalanceattribute',
        4 => 'app\\models\\newfactory',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Traits/HasTenant.php' => 
    array (
      0 => 'd8f2c6d028a1c5e52a5ab1195d88672dc14da4f0',
      1 => 
      array (
        0 => 'app\\traits\\hastenant',
      ),
      2 => 
      array (
        0 => 'app\\traits\\boothastenant',
        1 => 'app\\traits\\getcurrentorganizationid',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Resources/OrganizationResource.php' => 
    array (
      0 => '79dcd8e3e9695b60763e71038326e611ce9b9c36',
      1 => 
      array (
        0 => 'app\\http\\resources\\organizationresource',
      ),
      2 => 
      array (
        0 => 'app\\http\\resources\\toarray',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Resources/ServiceRequestResource.php' => 
    array (
      0 => '0b53daac307063e4461c1f3c74ac1f6527196990',
      1 => 
      array (
        0 => 'app\\http\\resources\\servicerequestresource',
      ),
      2 => 
      array (
        0 => 'app\\http\\resources\\toarray',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Resources/CategoryResource.php' => 
    array (
      0 => '7d67f9900ce26bd0e859d6ace7ec0189ead1646f',
      1 => 
      array (
        0 => 'app\\http\\resources\\categoryresource',
      ),
      2 => 
      array (
        0 => 'app\\http\\resources\\toarray',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Resources/SubscriptionResource.php' => 
    array (
      0 => '1a1bad1f0b750aa1433c4923956277a83fb35a78',
      1 => 
      array (
        0 => 'app\\http\\resources\\subscriptionresource',
      ),
      2 => 
      array (
        0 => 'app\\http\\resources\\toarray',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Resources/DocumentResource.php' => 
    array (
      0 => '51479ebc498e58744bc13d9a8372bf836c0f8248',
      1 => 
      array (
        0 => 'app\\http\\resources\\documentresource',
      ),
      2 => 
      array (
        0 => 'app\\http\\resources\\toarray',
        1 => 'app\\http\\resources\\formatbytes',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Resources/UserResource.php' => 
    array (
      0 => 'ea477ec0e7dc87e515879d68a402ba0286e3e4bb',
      1 => 
      array (
        0 => 'app\\http\\resources\\userresource',
      ),
      2 => 
      array (
        0 => 'app\\http\\resources\\toarray',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Resources/AccountResource.php' => 
    array (
      0 => 'e6a08f832e5eac3afb1da52937153f208f314bd0',
      1 => 
      array (
        0 => 'app\\http\\resources\\accountresource',
      ),
      2 => 
      array (
        0 => 'app\\http\\resources\\toarray',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Resources/NotificationResource.php' => 
    array (
      0 => 'fad55155cd3dc193b11e2c0519ed90d8c16b5372',
      1 => 
      array (
        0 => 'app\\http\\resources\\notificationresource',
      ),
      2 => 
      array (
        0 => 'app\\http\\resources\\toarray',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Resources/TransactionResource.php' => 
    array (
      0 => '5e111adb0a6ebdadab955a88cd3b94454ea0c394',
      1 => 
      array (
        0 => 'app\\http\\resources\\transactionresource',
      ),
      2 => 
      array (
        0 => 'app\\http\\resources\\toarray',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Resources/DueItemResource.php' => 
    array (
      0 => '9dec91388500bc539d43b792e50b8a67f96959e0',
      1 => 
      array (
        0 => 'app\\http\\resources\\dueitemresource',
      ),
      2 => 
      array (
        0 => 'app\\http\\resources\\toarray',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Resources/ServiceRequestCommentResource.php' => 
    array (
      0 => '121f242e20af1454d3a119017329cf2620c350f1',
      1 => 
      array (
        0 => 'app\\http\\resources\\servicerequestcommentresource',
      ),
      2 => 
      array (
        0 => 'app\\http\\resources\\toarray',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/ServiceRequestCommentController.php' => 
    array (
      0 => '3d7b5911a0da0414a018a0fa2a9f23971cc02817',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\servicerequestcommentcontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\store',
        1 => 'app\\http\\controllers\\api\\update',
        2 => 'app\\http\\controllers\\api\\destroy',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/DocumentController.php' => 
    array (
      0 => 'aa87127533895cc05890eb09f5aae6c515e634bd',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\documentcontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\index',
        1 => 'app\\http\\controllers\\api\\store',
        2 => 'app\\http\\controllers\\api\\show',
        3 => 'app\\http\\controllers\\api\\update',
        4 => 'app\\http\\controllers\\api\\destroy',
        5 => 'app\\http\\controllers\\api\\download',
        6 => 'app\\http\\controllers\\api\\url',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/TransactionController.php' => 
    array (
      0 => 'b30620b5675b84f508f176d8a21a65eac3e4cd67',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\transactioncontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\index',
        1 => 'app\\http\\controllers\\api\\store',
        2 => 'app\\http\\controllers\\api\\show',
        3 => 'app\\http\\controllers\\api\\update',
        4 => 'app\\http\\controllers\\api\\destroy',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/AuthController.php' => 
    array (
      0 => 'f6525a1d46310c1fd2ffbd477b15207234d78ad0',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\authcontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\login',
        1 => 'app\\http\\controllers\\api\\me',
        2 => 'app\\http\\controllers\\api\\logout',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/DueItemController.php' => 
    array (
      0 => 'bf4fed17c6bf07ddbb7274cfc23a00853a38861a',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\dueitemcontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\index',
        1 => 'app\\http\\controllers\\api\\store',
        2 => 'app\\http\\controllers\\api\\show',
        3 => 'app\\http\\controllers\\api\\update',
        4 => 'app\\http\\controllers\\api\\destroy',
        5 => 'app\\http\\controllers\\api\\markpaid',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/CategoryController.php' => 
    array (
      0 => 'f9ef3ed352a18ddad2408a8243fc44451bb9e6ef',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\categorycontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\index',
        1 => 'app\\http\\controllers\\api\\store',
        2 => 'app\\http\\controllers\\api\\show',
        3 => 'app\\http\\controllers\\api\\update',
        4 => 'app\\http\\controllers\\api\\destroy',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/DashboardController.php' => 
    array (
      0 => '00add77e7c4b96a26bf234e7175ae37d2594ec75',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\dashboardcontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\index',
        1 => 'app\\http\\controllers\\api\\getfinancialsummary',
        2 => 'app\\http\\controllers\\api\\getrecenttransactions',
        3 => 'app\\http\\controllers\\api\\getupcomingdueitems',
        4 => 'app\\http\\controllers\\api\\getoverdueitems',
        5 => 'app\\http\\controllers\\api\\getaccountbalances',
        6 => 'app\\http\\controllers\\api\\getmonthlyincomeexpense',
        7 => 'app\\http\\controllers\\api\\gettopcategories',
        8 => 'app\\http\\controllers\\api\\getcashflowprojection',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/AccountController.php' => 
    array (
      0 => 'bee5fec4d93e0f3442dfb0c5f302eeb78389f3f0',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\accountcontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\index',
        1 => 'app\\http\\controllers\\api\\store',
        2 => 'app\\http\\controllers\\api\\show',
        3 => 'app\\http\\controllers\\api\\update',
        4 => 'app\\http\\controllers\\api\\destroy',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/SubscriptionController.php' => 
    array (
      0 => 'bc339cbcfdae3bea9cf6168cfbb0fb3b0489c2d8',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\subscriptioncontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\getstripe',
        1 => 'app\\http\\controllers\\api\\show',
        2 => 'app\\http\\controllers\\api\\update',
        3 => 'app\\http\\controllers\\api\\cancel',
        4 => 'app\\http\\controllers\\api\\getstripepriceid',
        5 => 'app\\http\\controllers\\api\\createstripesubscription',
        6 => 'app\\http\\controllers\\api\\webhook',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/NotificationController.php' => 
    array (
      0 => '4d631bd642eb9a6ebc274857efe75405a8308590',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\notificationcontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\index',
        1 => 'app\\http\\controllers\\api\\unreadcount',
        2 => 'app\\http\\controllers\\api\\markasread',
        3 => 'app\\http\\controllers\\api\\markallasread',
        4 => 'app\\http\\controllers\\api\\destroy',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/ReportController.php' => 
    array (
      0 => '0b84f4b43b3bd840172bea8a00a577ce9ca66c1c',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\reportcontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\pl',
        1 => 'app\\http\\controllers\\api\\groupbycategory',
        2 => 'app\\http\\controllers\\api\\groupbymonth',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Api/ServiceRequestController.php' => 
    array (
      0 => 'ecc1e59a0aea25a50564326797fbe4c1ff2cf7d7',
      1 => 
      array (
        0 => 'app\\http\\controllers\\api\\servicerequestcontroller',
      ),
      2 => 
      array (
        0 => 'app\\http\\controllers\\api\\index',
        1 => 'app\\http\\controllers\\api\\store',
        2 => 'app\\http\\controllers\\api\\show',
        3 => 'app\\http\\controllers\\api\\update',
        4 => 'app\\http\\controllers\\api\\destroy',
        5 => 'app\\http\\controllers\\api\\markinprogress',
        6 => 'app\\http\\controllers\\api\\markresolved',
        7 => 'app\\http\\controllers\\api\\markclosed',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Controllers/Controller.php' => 
    array (
      0 => 'a33a5105f92c73a309c9f8a549905dcdf6dccbae',
      1 => 
      array (
        0 => 'app\\http\\controllers\\controller',
      ),
      2 => 
      array (
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Middleware/EnsureEmailIsVerified.php' => 
    array (
      0 => '730c6388eef41015c418ba8577f7526ab2a50167',
      1 => 
      array (
        0 => 'app\\http\\middleware\\ensureemailisverified',
      ),
      2 => 
      array (
        0 => 'app\\http\\middleware\\handle',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Middleware/CheckPlanLimit.php' => 
    array (
      0 => '06815aea907e1aada2edf549a8491d460d34a570',
      1 => 
      array (
        0 => 'app\\http\\middleware\\checkplanlimit',
      ),
      2 => 
      array (
        0 => 'app\\http\\middleware\\handle',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Middleware/EnsureTenantIsSet.php' => 
    array (
      0 => '2fa556e343a5c776b69b6b718ddd8e33fc4bfd8a',
      1 => 
      array (
        0 => 'app\\http\\middleware\\ensuretenantisset',
      ),
      2 => 
      array (
        0 => 'app\\http\\middleware\\handle',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Requests/CategoryRequest.php' => 
    array (
      0 => '98f5c11e528b88a447a7e8f514b1c9920e188782',
      1 => 
      array (
        0 => 'app\\http\\requests\\categoryrequest',
      ),
      2 => 
      array (
        0 => 'app\\http\\requests\\authorize',
        1 => 'app\\http\\requests\\rules',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Requests/DueItemRequest.php' => 
    array (
      0 => 'b28aa8a4f633d82742a5f7706ea066843d3e8fd3',
      1 => 
      array (
        0 => 'app\\http\\requests\\dueitemrequest',
      ),
      2 => 
      array (
        0 => 'app\\http\\requests\\authorize',
        1 => 'app\\http\\requests\\rules',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Requests/TransactionRequest.php' => 
    array (
      0 => '7fae21ce4175cd3e512576346909ddbca837b2df',
      1 => 
      array (
        0 => 'app\\http\\requests\\transactionrequest',
      ),
      2 => 
      array (
        0 => 'app\\http\\requests\\authorize',
        1 => 'app\\http\\requests\\rules',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Requests/Auth/LoginRequest.php' => 
    array (
      0 => '77bb7c5fc2fa01d8c1ed5c2490284a33dcf93e04',
      1 => 
      array (
        0 => 'app\\http\\requests\\auth\\loginrequest',
      ),
      2 => 
      array (
        0 => 'app\\http\\requests\\auth\\authorize',
        1 => 'app\\http\\requests\\auth\\rules',
        2 => 'app\\http\\requests\\auth\\authenticate',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Requests/AccountRequest.php' => 
    array (
      0 => '6e866df5fb60ac98e976c2a2f460e311046d98f7',
      1 => 
      array (
        0 => 'app\\http\\requests\\accountrequest',
      ),
      2 => 
      array (
        0 => 'app\\http\\requests\\authorize',
        1 => 'app\\http\\requests\\rules',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Requests/ServiceRequestRequest.php' => 
    array (
      0 => '2e86257e51707fde9bde52f27a48fb104264498c',
      1 => 
      array (
        0 => 'app\\http\\requests\\servicerequestrequest',
      ),
      2 => 
      array (
        0 => 'app\\http\\requests\\authorize',
        1 => 'app\\http\\requests\\rules',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Requests/DocumentRequest.php' => 
    array (
      0 => '0c37c3052ac5fd9ddd13df93e5a95092c8484b58',
      1 => 
      array (
        0 => 'app\\http\\requests\\documentrequest',
      ),
      2 => 
      array (
        0 => 'app\\http\\requests\\authorize',
        1 => 'app\\http\\requests\\rules',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Http/Requests/ServiceRequestCommentRequest.php' => 
    array (
      0 => '37bd345f83dfae63cc28ea909f9cc3a597cd870b',
      1 => 
      array (
        0 => 'app\\http\\requests\\servicerequestcommentrequest',
      ),
      2 => 
      array (
        0 => 'app\\http\\requests\\authorize',
        1 => 'app\\http\\requests\\rules',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Jobs/SendDueItemReminderJob.php' => 
    array (
      0 => '16d622701f0c3cfb35217d10f42f7b7d950c1a9a',
      1 => 
      array (
        0 => 'app\\jobs\\senddueitemreminderjob',
      ),
      2 => 
      array (
        0 => 'app\\jobs\\__construct',
        1 => 'app\\jobs\\handle',
      ),
      3 => 
      array (
      ),
    ),
    '/var/www/html/app/Scopes/TenantScope.php' => 
    array (
      0 => '646cbbb177583f8acac64786c576732de54e5061',
      1 => 
      array (
        0 => 'app\\scopes\\tenantscope',
      ),
      2 => 
      array (
        0 => 'app\\scopes\\apply',
        1 => 'app\\scopes\\extend',
        2 => 'app\\scopes\\getorganizationid',
      ),
      3 => 
      array (
      ),
    ),
  ),
));