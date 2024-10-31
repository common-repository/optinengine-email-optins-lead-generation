<?php

/**
* Plugin Name: OptinEngine - Email Optins & Lead Generation
* Description: Email optin forms, notification bars, sliders and modals for link promotion and email collection
* Version: 2.2.3
* Plugin URI: http://optinengine.net
* Author: OptinEngine
* Author URI: http://optinengine.net
* Requires at least: 4.6.0
* Tested up to: 4.7.2
*
* OptinEngine is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 2 of the License, or
* any later version.
*
* OptinEngine is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with OptinEngine. If not, see <http://www.gnu.org/licenses/>.
**/

if (!class_exists('Mobile_Detect')) {
  require_once(plugin_dir_path(__FILE__) . "libs/Mobile_Detect.php");
}

if (!class_exists('MailChimp')) {
  require_once(plugin_dir_path(__FILE__) . "libs/MailChimp.php");
}

if (!class_exists('GetResponse')) {
  require_once(plugin_dir_path(__FILE__) . "libs/GetResponse.php");
}

if (!class_exists('Aweber')) {
  require_once(plugin_dir_path(__FILE__) . "libs/Aweber.php");
}

if (!class_exists('Drip')) {
  require_once(plugin_dir_path(__FILE__) . "libs/Drip.php");
}

if (!class_exists('CampaignMonitor')) {
  require_once(plugin_dir_path(__FILE__) . "libs/CampaignMonitor.php");
}

if (!class_exists('Intercom')) {
  require_once(plugin_dir_path(__FILE__) . "libs/Intercom.php");
}

if (!class_exists('ActiveCampaign')) {
  require_once(plugin_dir_path(__FILE__) . "libs/ActiveCampaign.php");
}

if( file_exists(plugin_dir_path(__FILE__) . '/libs/js-wp-editor.php')) {
  require_once(plugin_dir_path(__FILE__) . '/libs/js-wp-editor.php');
}

if( file_exists(plugin_dir_path(__FILE__) . '/libs/Logging.php')) {
  require_once(plugin_dir_path(__FILE__) . '/libs/Logging.php');
}

if (!class_exists('OptinEngineWidget')) {
  require_once(plugin_dir_path(__FILE__) . "libs/OptinEngineWidget.php");
}

if (!defined('ABSPATH')) exit;

class OptinEngineLite {

  private static $_instance = null;

  public function __construct() {
    add_action('wp_footer', array($this, 'init_bar'));
    add_action('wp_enqueue_scripts', array($this, 'add_scripts'));
    add_action('init', array($this, 'init'));
    add_action('activated_plugin', array($this, 'activate_redirect'));

    // setup the database
    register_activation_hook(__FILE__, array($this, 'install'));
    register_uninstall_hook(__FILE__, array('OptinEngine', 'uninstall'));

    // register public facing ajax
    $this->register_global_ajax('optinengine_get_promo', array($this, 'ajax_get_promo'));
    $this->register_global_ajax('optinengine_get_promos', array($this, 'ajax_get_promos'));
    $this->register_global_ajax('optinengine_add_lead', array($this, 'ajax_add_lead'));

    // register admin ajax
    $this->register_admin_ajax('optinengine_boot', array($this, 'ajax_boot'));
    $this->register_admin_ajax('optinengine_update_promo', array($this, 'ajax_update_promo'));
    $this->register_admin_ajax('optinengine_delete_promo', array($this, 'ajax_delete_promo'));
    $this->register_admin_ajax('optinengine_empty_lead_list', array($this, 'ajax_empty_lead_list'));
    $this->register_admin_ajax('optinengine_get_leads', array($this, 'ajax_get_leads'));
    $this->register_admin_ajax('optinengine_delete_lead', array($this, 'ajax_delete_lead'));
    $this->register_admin_ajax('optinengine_register_mailchimp_account', array($this, 'ajax_register_mailchimp_account'));
    $this->register_admin_ajax('optinengine_refresh_provider_lists', array($this, 'ajax_refresh_provider_lists'));
    $this->register_admin_ajax('optinengine_delete_email_provider', array($this, 'ajax_delete_email_provider'));
    $this->register_admin_ajax('optinengine_register_getresponse_account', array($this, 'ajax_register_getresponse_account'));
    $this->register_admin_ajax('optinengine_register_aweber_account', array($this, 'ajax_register_aweber_account'));
    $this->register_admin_ajax('optinengine_register_drip_account', array($this, 'ajax_register_drip_account'));
    $this->register_admin_ajax('optinengine_register_campaignmonitor_account', array($this, 'ajax_register_campaignmonitor_account'));
    $this->register_admin_ajax('optinengine_register_intercom_account', array($this, 'ajax_register_intercom_account'));
    $this->register_admin_ajax('optinengine_register_activecampaign_account', array($this, 'ajax_register_activecampaign_account'));
    $this->register_admin_ajax('optinengine_update_affiliate_settings', array($this, 'ajax_update_affiliate_settings'));
    $this->register_admin_ajax('optinengine_update_logging_settings', array($this, 'ajax_update_logging_settings'));
    
    // download leads as csv
    add_action('plugins_loaded', array($this, 'export_lead_data'));

    // perform redirect goal
    add_action('plugins_loaded', array($this, 'export_link_redirect'));

    // perform redirect goal
    add_action('plugins_loaded', array($this, 'download_logs'));

    // add the admin menu
    add_action('admin_menu', array($this, 'options_page'));
    add_action('admin_enqueue_scripts', array($this, 'load_admin_scripts'));

    add_filter('the_content', array($this, 'display_before_after_post'), 9999);
    add_shortcode('optinengine_promo', array($this, 'optinengine_shortcode'));

    add_action('widgets_init', array($this, 'register_optinengine_widget'));

    // if we are in preview mode then don't show the admin bar 
    if (isset($_GET['optinengine-preview'])) {
      add_filter('show_admin_bar', '__return_false');
    }
  }

  function register_optinengine_widget() {
    register_widget('OptinEngineWidget');
  }

  function display_before_after_post($content) {
    return '<div class="optinengine_before_post"></div>'.$content.'<div class="optinengine_after_post"></div>';
  }

  function optinengine_shortcode( $atts ) {
    extract(
      shortcode_atts(
        array('promo_id' => 'invalid'),
        $atts
      )
    );
  
    return sprintf('<div data-optinengine-promo-%1$s="true"></div>',
      esc_html($promo_id)
    );
  }

  public static function instance($parent) {
    if (is_null(self::$_instance)) {
      self::$_instance = new self($parent);
    }
    return self::$_instance;
  }

  function get_page_type() {
    if (is_front_page()) {
      return 'front';
    }
    if (is_archive()) {
      return 'archive';
    }
    if (is_page()) {
      return 'page';
    }
    if (is_page()) {
      return 'page';
    }
    if (is_single()) {
      return 'post';
    }
    return 'unknown';
  }

  public function bar_script() {
    ?>
    <script type="text/javascript">
      OptinEngine.load({
        api: '<?php echo admin_url('admin-ajax.php'); ?>',
        tools: '<?php echo admin_url('tools.php'); ?>',
        autoLoad: <?php echo isset($_GET['optinengine-preview']) ? 'false' : 'true' ?>,
        editor: <?php echo isset($_GET['optinengine-preview']) ? 'true' : 'false' ?>,
        pageType: '<?php echo $this->get_page_type(); ?>',
        url: '<?php echo $_SERVER['REQUEST_URI'] ?>',
        pluginPath: '<?php echo plugins_url('/', __FILE__) ?>'
      })
      <?php if (isset($_GET['optinengine-preview'])): ?>
      OptinEngine.disableClicks()
      <?php endif ?>
    </script>
    <?php
  }

  public function init_bar() { 
    $this->bar_script();
  }

  function init()
  {
    $this->create_tables();
    if (isset($_GET['optinengine-preview'])) {
      ?>
      <html>
      <head>
        <script src="<?php echo plugins_url('dist/client/app.js?v=2.2.3', __FILE__) ?>"></script>
        <style type="text/css">
          body {
            background-color: #888;
            margin: 0px;
            font-family: Tahoma, Verdana, Segoe, sans-serif;
          }

          table {
            width: 100%;
            height: 100%;
          }

          .container {
            margin: 0 auto;
          }
        </style>
      </head>
      <body>
        <table>
          <tr>
            <td valign="middle">
              <div class="container"></div>
            </td>
          </tr>
        </table>

        <?php $this->bar_script() ?>
      </body>
      </html>
      <?php
      die();
    }
  }

  function _init()
  {
    $this->create_tables();
    if (isset($_GET['optinengine-preview'])) {
      ?>
      <html>
      <head>
        <script src="<?php echo plugins_url('dist/client/app.js?v=2.2.3', __FILE__) ?>"></script>
        <style type="text/css">
          body {
            background-color: #d0d0d0;
            margin: 0px;
            font-family: Tahoma, Verdana, Segoe, sans-serif;
          }
          header,
          footer,
          .template-body {
            max-width: 1024px;
            width: 90%;
            margin: 0 auto;
          }

          header,
          footer {
            padding: 30px 0;
          }

          header,
          footer,
          .template-body td {
            background-color: #ddd;
          }

          .template-body td {
          }

          .template-body table {
            width: 100%;
          }

          header,
          .template-body {
            margin-bottom: 5px;
          }

          .sidebar {
            width: 250px;
            border-left: 5px solid #eee;
          }

          .template-body {
          }

          .post {
            color: #aaa;
            padding: 20px;
          }

        </style>
      </head>
      <body>
        <header></header>

        <div class="template-body">
          <table cellspacing="0" cellpadding="0">
            <tr>
              <td valign="top">
                <div class="before-post"></div>
                <div class="post">
                  <h1>Example post or page</h1>
                  <p>
                  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus neque purus, vulputate sit amet velit ac, facilisis egestas lacus. Vestibulum cursus blandit justo, vitae tempus lorem viverra eu. Curabitur vel augue a tellus posuere varius. Aliquam vitae ante non purus congue euismod. Mauris id elementum tortor, et iaculis ipsum. Suspendisse potenti. Ut mi mauris, sodales sed quam nec, finibus placerat purus.
                  </p>

                  <div class="inline"></div>

                  <p>
                  Aenean et pellentesque tortor. Morbi condimentum nunc vitae libero placerat, in dignissim dui sollicitudin. Curabitur lacus eros, aliquet sit amet gravida vel, blandit eget tortor. Nulla nec tempor leo. Nunc ac nisl non turpis venenatis mattis quis sit amet lacus. Donec sed accumsan nulla. Sed fermentum mauris in ante venenatis convallis. Sed tortor justo, tincidunt nec blandit sed, sagittis sit amet metus.
                  </p>

                </div>
                <div class="after-post"></div>
              </td>
              <td class="sidebar" valign="top"></td>
            </tr>
          </table>
        </div>

        <footer></footer>

        <?php $this->bar_script() ?>
      </body>
      </html>
      <?php
      die();
    }
  }

  public function options_page()
  {
    add_menu_page(
      'OptinEngine',
      'OptinEngine',
      'manage_options',
      'optinengine',
      Array($this, 'options_page_html')
    );
  }

  public function load_admin_scripts($hook) {
    if (strpos($hook, 'optinengine') === false) {
      return;
    }
    wp_enqueue_script(
      'optinengine-main-script',
      plugins_url('/dist/admin/app.js?v=2.2.3', __FILE__),
      array(),
      '20161118',
      true
    );
    wp_enqueue_style(
      'optinengine-main-font',
      'https://fonts.googleapis.com/css?family=Open+Sans:400,600,700'
    );

    add_filter('mce_external_plugins', array($this, 'register_tinymce_javascript'));
    js_wp_editor();
    wp_enqueue_media();
  }

  function register_tinymce_javascript($plugin_array) {
    $plugin_array['link'] = plugins_url('/libs/tinymce/link/plugin.min.js?v=2.2.3', __FILE__);
    return $plugin_array;
  }

  public function add_scripts() {
    wp_enqueue_script(
      'optinengine-main-script',
      plugins_url('dist/client/app.js?v=2.2.3', __FILE__),
      array(),
      '20161118'
    );
  }

  public function export_lead_data() {
    global $pagenow;
    if ($pagenow != 'tools.php' ||
      current_user_can('export') == false || 
      isset($_GET['action']) == false || 
      $_GET['action'] != 'optinengine-export-leads') {
      return;
    }

    header("Content-Disposition: attachment; filename=optinengine-leads.csv");
    header("Pragma: no-cache");
    header("Expires: 0");

    $leads = $this->get_all_leads();

    if ($leads) {
      foreach ($leads as $lead) {
        echo sprintf('"%s","%s","%s","%s"',
          addslashes($lead->email),
          addslashes($lead->name),
          addslashes($lead->last_name),
          $lead->created_at);
        echo "\n";
      }
    }
    exit();
  }

  public function export_link_redirect() {
    global $pagenow;
    if ($pagenow != 'tools.php' ||
      isset($_GET['action']) == false || 
      $_GET['action'] != 'optinengine-redirect') {
      return;
    }

    if (isset($_GET['promo']) == false) {
      wp_redirect("/");
      die();
    }

    // get the promo
    $promo_id = intval($_GET['promo']);
    $promo = $this->get_promo($promo_id);

    // set the hidden cookie
    if ($promo->successCookieDuration != 0) {
      $hidden_cookie_key = "optinengine-promo-hidden-" . $promo_id;
      $cookie_expires = time() + (86400 * $promo->successCookieDuration);
      setcookie($hidden_cookie_key, "1", $cookie_expires);
    }

    wp_redirect($promo->linkUrl);
    exit();
  }

  public function get_promo($promo_id) {
    return json_decode($this->get_promo_spec($promo_id));
  }

  public static function promo_table() {
    global $wpdb;
    return $wpdb->prefix . 'optinengine_promos';
  }

  public static function leads_table() {
    global $wpdb;
    return $wpdb->prefix . 'optinengine_leads';
  }

  public static function providers_table() {
    global $wpdb;
    return $wpdb->prefix . 'optinengine_providers';
  }

  public static function lists_table() {
    global $wpdb;
    return $wpdb->prefix . 'optinengine_provider_lists';
  }

  public function get_all_promos() {
    global $wpdb;
    $table_name = self::promo_table();
    $results = $wpdb->get_results("SELECT * FROM $table_name ORDER BY id");
    $this->check_wpdb_error();
    return array_map(array($this, "promo_to_result"), $results);
  }

  function get_enabled_promos() {
    global $wpdb;
    $table_name = self::promo_table();
    $results = $wpdb->get_results("SELECT * FROM $table_name ORDER BY RAND()");
    $this->check_wpdb_error();
    return $results;
  }

  function add_optinengine_lead($promo_id, $email, $name, $last_name, $ip) {
    $this->write_log(
      Array(
        'function' => __FUNCTION__,
        'message' => 'Adding OptinEngine lead',
        'promo_id' => $promo_id,
        'email' => $email,
        'name' => $name,
        'last_name' => $last_name,
        'ip' => $ip
      )
    );

    global $wpdb;
    $promos_table = self::promo_table();
    $leads_table = self::leads_table();
    $sha1 = sha1($promo_id.$ip);

    // Verify input
    $verify_info = $wpdb->get_row($wpdb->prepare(
      "
      SELECT 
        (EXISTS(
          SELECT id 
          FROM $promos_table 
          WHERE id=%d
        )) promo_ok,
        (NOT EXISTS (
          SELECT id
          FROM $leads_table
          WHERE `ip_hash`=%s
          AND TIMESTAMPDIFF(MINUTE,`created_at`,now()) < 60
        )) ip_ok
      ",
      $promo_id,
      $sha1
    ));

    $this->check_wpdb_error();

    // if OK then insert the record
    if (
      $verify_info != null &&
      $verify_info->promo_ok &&
      $verify_info->ip_ok
    ) {
      $query = $wpdb->prepare(
        "
        INSERT INTO $leads_table
          (email, name, last_name, created_at, ip_hash) 
        VALUES 
          (%s, %s, %s, now(), %s)
        ON DUPLICATE KEY 
          UPDATE `name`=%s, `last_name`=%s, `created_at`=now(), `ip_hash`=%s",
        $email, $name, $last_name, $sha1, $name, $last_name, $sha1
      );
      $wpdb->query($query);
      $this->check_wpdb_error();
      $this->write_log(
        Array(
          'function' => __FUNCTION__,
          'message' => 'Added OK',
          'verify' => $verify_info
        )
      );

      return true;
    } else {

      $this->write_log(
        Array(
          'function' => __FUNCTION__,
          'message' => 'Unable to add (add query returned false)',
          'verify' => $verify_info
        )
      );

      return false;
    }
  }

  function add_lead($promo_id, $email, $name, $last_name, $ip) {

    global $wpdb;

    $this->write_log(
      Array(
        'function' => __FUNCTION__,
        'message' => 'Adding lead',
        'promo_id' => $promo_id,
        'email' => $email,
        'name' => $name,
        'last_name' => $last_name,
        'ip' => $ip
      )
    );

    $promo = $this->get_promo($promo_id);
    $provider_table = self::providers_table();
    $lists_table = self::lists_table();

    // get the provider
    $list = $wpdb->get_row($wpdb->prepare(
      "
      SELECT p.id provider_id, p.provider, p.data provider_data, l.identifier
      FROM $lists_table l
      INNER JOIN $provider_table p
        ON p.id = l.provider_id
      WHERE p.id=%s and identifier = %s;
      ",
      $promo->emailProvider,
      $promo->emailProviderListId
    ));
    $this->check_wpdb_error();

    if ($list == null || $promo->emailProvider == "optinengine") {
      $this->add_optinengine_lead($promo_id, $email, $name, $last_name, $ip);
      return;
    } else {

      try {
        $provider_data = json_decode($list->provider_data);
        $add_to_optinengine = false;
        $api = null;

        $this->write_log(
          Array(
            'function' => __FUNCTION__,
            'message' => 'Adding via API',
            'provider' => $list->provider
          )
        );

        switch ($list->provider) {
          case 'mailchimp':
            $api = new MailChimp();
            $api->set_auth(
              $provider_data->account_name,
              $provider_data->api_key
            );
            break;

          case 'getresponse':
            $api = new GetResponse();
            $api->set_auth($provider_data->api_key);
            break;

          case 'aweber':
            $api = new Aweber();
            $api->set_auth($provider_data);
            break;

          case 'drip':
            $api = new Drip();
            $api->set_auth(
              $provider_data->account_id,
              $provider_data->api_key
            );
            break;

          case 'campaignmonitor':
            $api = new CampaignMonitor();
            $api->set_auth(
              $provider_data->api_key
            );
            break;

          case 'intercom':
            $api = new Intercom();
            $api->set_auth(
              $provider_data->api_key
            );
            break;

          case 'activecampaign':
            $api = new ActiveCampaign();
            $api->set_auth(
              $provider_data->api_key,
              $provider_data->api_url
            );
            break;

          default: 
            $add_to_optinengine = true;
        }

        if ($api !== null) {
          $res = $api->add_lead(
            $list->identifier,
            $ip,
            $email,
            $name,
            $last_name,
            $promo->disableDoubleOptin
          );

          $this->write_log(
            Array(
              'function' => __FUNCTION__,
              'message' => 'Added via API',
              'res' => $res
            )
          );
        }
      } catch (Exception $e) {
        $this->write_log(
          Array(
            'function' => __FUNCTION__,
            'message' => 'Failed to add lead',
            'error' => $e->getMessage()
          )
        );
        $add_to_optinengine = true;
      }

      if ($add_to_optinengine || $promo->saveToOptinEngineLeads) {
        $this->add_optinengine_lead($promo_id, $email, $name, $last_name, $ip);
      }
    }
  }

  function delete_lead($lead_id) {
    global $wpdb;
    $wpdb->delete(
      self::leads_table(),
      array('id' => $lead_id),
      array('%d')
    );
    $this->check_wpdb_error();
  }

  function update_promo_spec($id, $spec) {
    global $wpdb;
    $table_name = self::promo_table();
    $query = $wpdb->prepare(
      "UPDATE $table_name SET spec = %s WHERE id = %d", $spec, $id
    );
    $wpdb->query($query);
    $this->check_wpdb_error();
  }

  function add_promo($spec) {
    global $wpdb;
    $table_name = self::promo_table();
    $query = $wpdb->prepare(
      "INSERT INTO $table_name (spec) values (%s)",
      $spec
    );
    $wpdb->query($query);
    $this->check_wpdb_error();
    return $wpdb->insert_id;
  }

  function get_default_lead_list_count() {
    global $wpdb;
    $leads = self::leads_table();
    $result = $wpdb->get_var("SELECT COUNT(id) FROM $leads;");
    $this->check_wpdb_error();
    return $result;
  }

  function delete_promo($promo_id) {
    global $wpdb;
    $wpdb->delete(
      self::promo_table(),
      array('id' => $promo_id),
      array('%d')
    );
    $this->check_wpdb_error();
  }

  function get_all_leads() {
    global $wpdb;
    $table_name = self::leads_table();
    $result = $wpdb->get_results("SELECT * FROM $table_name");
    $this->check_wpdb_error();
    return $result;
  }

  function empty_lead_list() {
    global $wpdb;
    $wpdb->delete(
      self::leads_table()
    );
    $this->check_wpdb_error();
  }

  function get_leads($last_id, $count) {
    global $wpdb;
    $table_name = self::leads_table();
    $query = $wpdb->prepare(
      "SELECT id, name, last_name, email, created_at FROM $table_name WHERE id<%d ORDER BY id DESC LIMIT %d",
      $last_id,
      $count
    );

    $result = $wpdb->get_results(
      $query
    );
    $this->check_wpdb_error();
    return $result;
  }

  function get_promo_spec($promo_id) {
    global $wpdb;
    $table = self::promo_table();
    $query = $wpdb->prepare(
      "SELECT `spec` FROM $table WHERE id = %d;",
      $promo_id
    );
    $result = $wpdb->get_var($query);
    $this->check_wpdb_error();
    return $result;
  }

  function ajax_send_ok() {
    wp_send_json(Array(
      "ok" => true
    ));
    die();
  }

  function register_global_ajax($action, $function_name) {
    add_action("wp_ajax_" . $action, $function_name);
    add_action("wp_ajax_nopriv_" . $action, $function_name);
  }

  function register_admin_ajax($action, $function_name) {
    add_action("wp_ajax_" . $action, $function_name);
  }

  function should_hide_after_sucess($spec) {
    switch ($spec->promoType) {
      case 'widget':
      case 'inline':
      case 'before-post':
      case 'after-post':
        return false;
      
      default:
        return true;
    }
  }

  function check_conditions($spec, $page_type, $url) {

    // has the user hidden/completed this promo?  
    $hidden_cookie_key = "optinengine-promo-hidden-" . $spec->id;
    if (isset($_COOKIE[$hidden_cookie_key]) && $this->should_hide_after_sucess($spec)) {
      return false;
    }

    if (!$spec->isEnabled) {
      return false;
    }

    // check the page type
    if (
      property_exists($spec, 'conditionPage') &&
      $spec->conditionPage != 'all'
    ) {
      if ($spec->conditionPage == $page_type) {
        return true;
      }
      if (
        property_exists($spec, 'conditionPageUrl') &&
        $spec->conditionPage == 'custom') {

        $path = parse_url($spec->conditionPageUrl, PHP_URL_PATH);
        $query = parse_url($spec->conditionPageUrl, PHP_URL_QUERY);

        if ($path) {
          if ($query != false && strlen($query)) {
            $path .= '?'.$query;
          }
          return $path == $url;
        }
        return $spec->conditionPageUrl == $url;
      }
      return false;
    }

    // check desktops
    $detect = new Mobile_Detect;
    $is_desktop = !($detect->isMobile() || $detect->isTablet());
    if (
      property_exists($spec, 'conditionDeviceDesktop') && 
      !$spec->conditionDeviceDesktop &&
      $is_desktop
    ) {
      return false;
    }

    // check tablets
    if (
      property_exists($spec, 'conditionDeviceTablet') && 
      !$spec->conditionDeviceTablet &&
      $detect->isTablet()
    ) {
      return false;
    }

    // check mobile
    if (
      property_exists($spec, 'conditionDeviceMobile') && 
      !$spec->conditionDeviceMobile &&
      $detect->isMobile()
    ) {
      return false;
    }
    return true;
  }

  public function ajax_get_promo() {

    $promos = $this->get_enabled_promos();
    $affiliate_id = get_option('optinengine_affiliate_id', '');
    $affiliate_enabled = get_option('optinengine_affiliate_enabled', '0') == "1";

    foreach ($promos as &$promo) {

      // check the conditions, page, visits, device etc. etc.
      // also check the bar is not hidden (check cookie)
      $spec = json_decode($promo->spec);

      // if we made it this far we can send to the client
      $spec->id = intval($promo->id);

      // make sure its not hidden (close or success)
      if (!$this->check_conditions(
        $spec,
        $_POST['page_type'],
        $_POST['url']
      )) {
        continue;
      }

      wp_send_json(Array(
        "promo" => $spec,
        "affiliate_id" => $affiliate_id,
        "affiliate_enabled" => $affiliate_enabled
      ));
      die();
      return;
    }
    wp_send_json(Array(
      "promo" => null,
      "affiliate_id" => $affiliate_id,
      "affiliate_enabled" => $affiliate_enabled
    ));
    die();
  }

  public function ajax_get_promos() {

    $promos = $this->get_enabled_promos();
    $affiliate_id = get_option('optinengine_affiliate_id', '');
    $affiliate_enabled = get_option('optinengine_affiliate_enabled', '0') == "1";
    $active_promos = Array();

    foreach ($promos as &$promo) {

      // check the conditions, page, visits, device etc. etc.
      // also check the bar is not hidden (check cookie)
      $spec = json_decode($promo->spec);

      // if we made it this far we can send to the client
      $spec->id = intval($promo->id);

      // make sure its not hidden (close or success)
      if (!$this->check_conditions(
        $spec,
        $_POST['page_type'],
        $_POST['url']
      )) {
        continue;
      }

      $active_promos[] = $spec;
    }

    wp_send_json(Array(
      "promos" => $active_promos,
      "affiliate_id" => $affiliate_id,
      "affiliate_enabled" => $affiliate_enabled
    ));

    die();
  }

  function promo_to_result($promo) {
    $promo_spec = json_decode($promo->spec);
    $promo_spec->id = intval($promo->id);
    return $promo_spec;
  }

  function lead_list_to_result($list) {
    return Array(
      "id" => intval($list->id),
      "name" => $list->name,
      "count" => intval($list->count)
    );
  }

  function get_lead_lists() {
    $lead_lists = array_map(
      array($this, "lead_list_to_result"),
      $this->get_all_lead_lists()
    );

    $default_list = array(
      "id" => 0,
      "name" => "My leads",
      "count" => intval($this->get_default_lead_list_count())
    );

    array_unshift(
      $lead_lists,
      $default_list
    );

    return $lead_lists;
  }

  function ajax_boot() {
    $promos = $this->get_all_promos();
    $email_providers = $this->get_all_email_providers();
    $user = wp_get_current_user();
    $affiliate_id = get_option('optinengine_affiliate_id', '');
    $affiliate_enabled = get_option('optinengine_affiliate_enabled', '0') == "1";
    $logging_enabled = get_option('optinengine_logging_enabled', '0') == "1";

    wp_send_json(
      Array(
        "promos" => $promos,
        "lead_count" => intval($this->get_default_lead_list_count()),
        "email_providers" => $email_providers,
        "user_email" => $user->user_email,
        "user_first_name" => $user->user_firstname,
        "user_last_name" => $user->user_lastname,
        "affiliate_id" => $affiliate_id,
        "affiliate_enabled" => $affiliate_enabled,
        "logging_enabled" => $logging_enabled
      )
    );
    die();
  }

  function ajax_update_promo() {
    $spec_json = stripslashes($_POST["spec"]);
    $spec = json_decode($spec_json);

    if ($spec === NULL) {
      return $this->send_fail("Invalid spec JSON");
    }

    $json = json_encode($spec);

    if (isset($_POST['id'])) {
      $promo_id = intval($_POST['id']);
      $this->update_promo_spec(
        $promo_id,
        $json
      );
    } else {
      $promo_id = $this->add_promo($json);
    }

    wp_send_json(Array(
      "ok" => true,
      "promo_id" => $promo_id
    ));

    $this->ajax_send_ok();
    die();
  }

  public function ajax_delete_promo() {
    $id = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);
    if ($id === null) {
      die("invalid input");
      return;
    }
    $this->delete_promo($id);
    $this->ajax_send_ok();
  }

  public function ajax_empty_lead_list() {
    $this->empty_lead_list();
    $this->ajax_send_ok();
  }

  public function ajax_rename_lead_list() {
    $id = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);
    $name = $_POST["name"];
    if ($id === null || strlen($name) == 0) {
      die("invalid input");
      return;
    }
    $this->rename_lead_list($id, stripslashes($name));
    $this->ajax_send_ok();
  }

  public function lead_to_result($lead) {
    $date = date_create($lead->created_at);

    return Array(
      "id" => intval($lead->id),
      "name" => $lead->name,
      "email" => $lead->email,
      "created_at" => date_format($date,"Y-m-d"),
      "last_name" => $lead->last_name
    );
  }

  public function ajax_get_leads() {
    $last_id = filter_input(INPUT_POST, 'last_id', FILTER_VALIDATE_INT);

    if (!$last_id) {
      $last_id = PHP_INT_MAX;
    }
    
    $max_results = 25;
    $leads = $this->get_leads($last_id, $max_results);
    wp_send_json(
      Array(
        "leads" => array_map(array($this, "lead_to_result"), $leads),
        "has_more" => count($leads) == $max_results
      )
    );
    die();
  }

  public function ajax_delete_lead() {
    $id = intval($_POST["id"]);
    $this->delete_lead($id);
    $this->ajax_send_ok();
  }

  function get_client_ip() {
    if (getenv('HTTP_CLIENT_IP'))
      return getenv('HTTP_CLIENT_IP');
    
    if (getenv('HTTP_X_FORWARDED_FOR'))
      return getenv('HTTP_X_FORWARDED_FOR');
    
    if (getenv('HTTP_X_FORWARDED'))
      return getenv('HTTP_X_FORWARDED');
    
    if (getenv('HTTP_FORWARDED_FOR'))
      return getenv('HTTP_FORWARDED_FOR');
    
    if (getenv('HTTP_FORWARDED'))
     return getenv('HTTP_FORWARDED');

    if (getenv('REMOTE_ADDR'))
      return getenv('REMOTE_ADDR');
    
    return 'UNKNOWN';
  }

  public function ajax_add_lead() {
    $promo_id = filter_input(INPUT_POST, 'promo_id', FILTER_VALIDATE_INT);
    $email = filter_input(INPUT_POST, 'email', FILTER_VALIDATE_EMAIL);
    $name = $_POST["name"];
    $last_name = $_POST["last_name"];

    if ($promo_id === null || $email === null) {
      die("Invalid input");
      return;
    }

    $this->add_lead(
      $promo_id,
      stripslashes($email),
      stripslashes($name),
      stripslashes($last_name),
      $this->get_client_ip()
    );

    $this->ajax_send_ok();
  }

  public function send_fail($error) {
    wp_send_json(Array("error" => $error), $status_code=500);
  }

  function plugin_admin_relative_path() {
    $url_parts = parse_url(plugins_url('/dist/admin/', __FILE__));
    return $url_parts["path"];
  }

  public function options_page_html()
  {
    // check user capabilities
    if (!current_user_can('manage_options')) {
      return;
    }
    ?>
    <script type="text/javascript">
      window._optinEngineAdminPublicPath = '<?php echo $this->plugin_admin_relative_path() ?>'
      document.addEventListener('DOMContentLoaded', (event) => {
        OptinEngineAdmin.load({
          api: '<?php echo admin_url('admin-ajax.php'); ?>',
          tools: '<?php echo admin_url('tools.php'); ?>',
          pluginPath: '<?php echo plugins_url('/', __FILE__) ?>'
        })
      })
    </script>
    <div id="optinengine-admin-container"></div>
    <?php
  }

  public function install() {
    add_option('optinengine_activation_redirect', true);
  }

  function activate_redirect($plugin) {
    if (get_option('optinengine_activation_redirect', false)) {
      delete_option('optinengine_activation_redirect');
      wp_redirect(esc_url(admin_url('admin.php?page=optinengine')));
      exit();
    }
  }

  public function create_tables() {
    global $wpdb;

    if (!current_user_can('activate_plugins'))
      return;

    $charset_collate = $wpdb->get_charset_collate();
    require_once(ABSPATH . 'wp-admin/includes/upgrade.php');

    $table = self::promo_table();
    dbDelta("CREATE TABLE `$table` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `spec` text NOT NULL,
      PRIMARY KEY (`id`)
    ) $charset_collate;");

    // TODO : 180 is max able to create without going over the unique key limit, try on myisam
    $table = self::leads_table();
    dbDelta("CREATE TABLE `$table` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `list_id` int(11) NOT NULL DEFAULT 0,
      `email` varchar(180) NOT NULL, 
      `name` varchar(256) DEFAULT NULL,
      `last_name` varchar(256) DEFAULT NULL,
      `created_at` datetime NOT NULL,
      `ip_hash` varchar(128) NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY ix_unique (`list_id`,`email`),
      KEY `ix_ip_created` (`ip_hash`,`created_at`),
      KEY `ix_list_id` (`list_id`)
    ) $charset_collate;");

    $table = self::providers_table();
    dbDelta("CREATE TABLE `$table` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `provider` varchar(64) NOT NULL, 
      `name` varchar(256) NOT NULL,
      `data` text NOT NULL,
      PRIMARY KEY (`id`)
    ) $charset_collate;");

    $table = self::lists_table();
    dbDelta("CREATE TABLE `$table` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `provider_id` int(11) NOT NULL,
      `name` varchar(256) NOT NULL,
      `subscribers` int(11) NOT NULL DEFAULT 0,
      `identifier` varchar(128) NOT NULL,
      PRIMARY KEY (`id`),
      KEY `ix_provider_id` (`provider_id`),
      UNIQUE KEY ix_unique (`provider_id`,`identifier`)
    ) $charset_collate;");
  }

  public static function uninstall()
  {
    if (!current_user_can('activate_plugins'))
      return;

    // delete all the tables we created at install
    /*
    global $wpdb;
    $table_leads = self::leads_table();
    $promos_table = self::promo_table();
    $wpdb->query("DROP TABLE IF EXISTS $table_leads;");
    $wpdb->query("DROP TABLE IF EXISTS $promos_table;");
    */
  }

  public function ajax_register_mailchimp_account() {
    $account_name = $_POST["account_name"];
    $api_key = $_POST["api_key"];

    if ($account_name === null || $api_key === null) {
      return $this->send_fail("Invalid input");
    }
    try {
      $mailchimp = new MailChimp();
      $mailchimp->set_auth($account_name, $api_key);

      // get the lists
      $mailchimp->get_lists();

      $provider_id = $this->add_email_provider(
        'mailchimp',
        $account_name,
        array(
          'account_name' => $account_name,
          'api_key' => $api_key
        )
      );

      $this->refresh_email_provider_lists($provider_id);
      $this->ajax_send_ok();

    } catch (Exception $e) {
      $this->write_log(
        Array(
          'function' => __FUNCTION__,
          'message' => 'Failed to register MailChimp',
          'error' => $e->getMessage()
        )
      );
      return $this->send_fail($e->getMessage());
    }
  }

  public function ajax_register_getresponse_account() {
    $account_name = $_POST["account_name"];
    $api_key = $_POST["api_key"];

    if ($account_name === null || $api_key === null) {
      return $this->send_fail("Invalid input");
    }
    try {
      $api = new GetResponse();
      $api->set_auth($api_key);

      // get the lists
      $api->get_lists();

      $provider_id = $this->add_email_provider(
        'getresponse',
        $account_name,
        array(
          'api_key' => $api_key
        )
      );

      $this->refresh_email_provider_lists($provider_id);
      $this->ajax_send_ok();

    } catch (Exception $e) {
      $this->write_log(
        Array(
          'function' => __FUNCTION__,
          'message' => 'Failed to register GetResponse',
          'error' => $e->getMessage()
        )
      );
      return $this->send_fail($e->getMessage());
    }
  }

  public function add_email_provider($provider, $name, $data) {
    $this->write_log(
      Array(
        'function' => __FUNCTION__,
        'message' => 'Adding email provider',
        'provider' => $provider,
        'name' => $name,
      )
    );

    global $wpdb;
    $wpdb->insert( 
      self::providers_table(), 
      array( 
        'provider' => $provider,
        'name' => $name,
        'data' => json_encode($data)
      ), 
      array('%s', '%s') 
    );
    $this->check_wpdb_error();
    return $wpdb->insert_id;
  }

  function get_email_provider($provider_id) {
    global $wpdb;
    $table = self::providers_table();
    $query = $wpdb->prepare(
      "SELECT * FROM $table WHERE id = %d;",
      $provider_id
    );
    $provider = $wpdb->get_row($query);
    $this->check_wpdb_error();
    $provider->data = json_decode($provider->data);
    return $provider;
  }

  function delete_email_provider_lists($provider_id) {
    global $wpdb;
    $wpdb->delete(
      self::lists_table(),
      array('provider_id' => $provider_id),
      array('%d')
    );
    $this->check_wpdb_error();
  }

  public function refresh_email_provider_lists($provider_id) {
    $provider = $this->get_email_provider($provider_id);
    $lists = null;
    $api = null;

    $this->write_log(
      Array(
        'function' => __FUNCTION__,
        'message' => 'Refreshing list',
        'provider' => $provider->provider
      )
    );

    switch ($provider->provider) {
      case 'mailchimp':
        $api = new MailChimp();
        $api->set_auth(
          $provider->data->account_name,
          $provider->data->api_key
        );
        break;

      case 'getresponse':
        $api = new GetResponse();
        $api->set_auth($provider->data->api_key);
        break;

      case 'aweber':
        $api = new Aweber();
        $api->set_auth($provider->data);
        break;

      case 'drip':
        $api = new Drip();
        $api->set_auth(
          $provider->data->account_id,
          $provider->data->api_key
        );
        break; 

      case 'campaignmonitor':
        $api = new CampaignMonitor();
        $api->set_auth(
          $provider->data->api_key
        );
        break;

      case 'intercom':
        $api = new Intercom();
        $api->set_auth(
          $provider->data->api_key
        );
        break;

      case 'activecampaign':
        $api = new ActiveCampaign();
        $api->set_auth(
          $provider->data->api_key,
          $provider->data->api_url
        );
        break;

      default:
        throw new Exception('Provider type not supported: ' . $provider->provider);
    }

    if ($api == null) {
      throw new Exception('No API defined for ' . $provider->provider);
    }

    $lists = $api->get_lists();

    if ($lists === null) {
      throw new Exception('Unable to load lists for this id');
    }

    // delete all current lists
    $this->delete_email_provider_lists($provider_id);

    // add the new lists
    foreach ($lists as $list) {
      $this->add_email_provider_list($provider_id, $list);
    }
  }

  public function add_email_provider_list($provider_id, $list) {
    global $wpdb;
    $table = self::lists_table();
    $wpdb->insert( 
      $table = self::lists_table(),
      array( 
        'provider_id' => $provider_id,
        'name' => $list->name,
        'subscribers' => $list->subscribers,
        'identifier' => $list->id
      ), 
      array('%s', '%s', '%s', '%s')
    );
    $this->check_wpdb_error();
    return $wpdb->insert_id;
  }

  function get_all_email_providers() {
    global $wpdb;
    $providers_table = self::providers_table();
    $lists_table = self::lists_table();

    $providers = $wpdb->get_results("SELECT id, provider, name FROM $providers_table ORDER BY id");
    $this->check_wpdb_error();
    foreach ($providers as $provider) {
      $provider->id =intval($provider->id);
      $query = $wpdb->prepare(
        "SELECT name, identifier, subscribers FROM $lists_table where provider_id=%d ORDER BY id;",
        $provider->id
      );
      $provider->lists = $wpdb->get_results($query);
      $this->check_wpdb_error();
      foreach ($provider->lists as $list) {
        $list->subscribers = intval($list->subscribers);
      }
    }
    return $providers;
  }

  function ajax_refresh_provider_lists() {
    $provider_id = $_POST["provider_id"];

    $this->write_log(
      Array(
        'function' => __FUNCTION__,
        'message' => 'Refreshing provider list'
      )
    );

    if ($provider_id === null) {
      return $this->send_fail("Invalid input");
    }
    try {
      $this->refresh_email_provider_lists($provider_id);
      $this->ajax_send_ok();
    } catch (Exception $e) {
      $this->write_log(
        Array(
          'function' => __FUNCTION__,
          'message' => 'Failed to refresh email provider',
          'error' => $e->getMessage()
        )
      );
      return $this->send_fail($e->getMessage());
    }
  }

  function ajax_delete_email_provider() {
    $provider_id = $_POST["provider_id"];
    global $wpdb;
    $wpdb->delete(
      self::lists_table(),
      array('provider_id' => $provider_id),
      array('%d')
    );
    $this->check_wpdb_error();
    $wpdb->delete(
      self::providers_table(),
      array('id' => $provider_id),
      array('%d')
    );
    $this->check_wpdb_error();
  }

  public function ajax_register_aweber_account() {
    $account_name = $_POST["account_name"];
    $api_key = $_POST["api_key"];

    if ($account_name === null || $api_key === null) {
      return $this->send_fail("Invalid input");
    }
    try {
      $api = new Aweber();
      $api_auth = $api->auth($api_key);

      $provider_id = $this->add_email_provider(
        'aweber',
        $account_name,
        $api_auth
      );

      $this->refresh_email_provider_lists($provider_id);
      $this->ajax_send_ok();

    } catch (Exception $e) {
      $this->write_log(
        Array(
          'function' => __FUNCTION__,
          'message' => 'Failed to register AWeber account',
          'error' => $e->getMessage()
        )
      );
      return $this->send_fail($e->getMessage());
    }
  }

  public function ajax_register_drip_account() {
    $account_name = $_POST["account_name"];
    $api_key = $_POST["api_key"];
    $account_id = $_POST["account_id"];

    if ($account_name === null || $api_key === null || !$account_id) {
      return $this->send_fail("Invalid input");
    }
    try {
      $api = new Drip();
      $api->set_auth(
        $account_id,
        $api_key
      );
      $api->auth();

      $provider_id = $this->add_email_provider(
        'drip',
        $account_name,
        array(
          'account_id' => $account_id,
          'api_key' => $api_key
        )
      );

      $this->refresh_email_provider_lists($provider_id);
      $this->ajax_send_ok();

    } catch (Exception $e) {
      $this->write_log(
        Array(
          'function' => __FUNCTION__,
          'message' => 'Failed to register Drip account',
          'error' => $e->getMessage()
        )
      );
      return $this->send_fail($e->getMessage());
    }
  }

  public function ajax_register_campaignmonitor_account() {
    $account_name = $_POST["account_name"];
    $api_key = $_POST["api_key"];

    if ($account_name === null || $api_key === null) {
      return $this->send_fail("Invalid input");
    }
    try {
      $api = new CampaignMonitor();
      $api->set_auth($api_key);
      $api->auth();

      $provider_id = $this->add_email_provider(
        'campaignmonitor',
        $account_name,
        array(
          'api_key' => $api_key
        )
      );

      $this->refresh_email_provider_lists($provider_id);
      $this->ajax_send_ok();

    } catch (Exception $e) {
      $this->write_log(
        Array(
          'function' => __FUNCTION__,
          'message' => 'Failed to register CampaignMonitor account',
          'error' => $e->getMessage()
        )
      );
      return $this->send_fail($e->getMessage());
    }
  }

  public function ajax_register_intercom_account() {
    $account_name = $_POST["account_name"];
    $api_key = $_POST["api_key"];

    if ($account_name === null || $api_key === null) {
      return $this->send_fail("Invalid input");
    }
    try {
      $api = new Intercom();
      $api->set_auth($api_key);
      $api->auth();

      $provider_id = $this->add_email_provider(
        'intercom',
        $account_name,
        array(
          'api_key' => $api_key
        )
      );

      $this->refresh_email_provider_lists($provider_id);
      $this->ajax_send_ok();

    } catch (Exception $e) {
      $this->write_log(
        Array(
          'function' => __FUNCTION__,
          'message' => 'Failed to register Intercom account',
          'error' => $e->getMessage()
        )
      );
      return $this->send_fail($e->getMessage());
    }
  }

  public function ajax_register_activecampaign_account() {
    $account_name = $_POST["account_name"];
    $api_key = $_POST["api_key"];
    $api_url = $_POST["api_url"];

    if ($account_name === null || $api_key === null || $api_url === null) {
      return $this->send_fail("Invalid input");
    }
    try {
      $api = new ActiveCampaign();
      $api->set_auth($api_key, $api_url);
      $api->auth();

      $provider_id = $this->add_email_provider(
        'activecampaign',
        $account_name,
        array(
          'api_key' => $api_key,
          'api_url' => $api_url
        )
      );

      $this->refresh_email_provider_lists($provider_id);
      $this->ajax_send_ok();

    } catch (Exception $e) {
      $this->write_log(
        Array(
          'function' => __FUNCTION__,
          'message' => 'Failed to register ActiveCampaign account',
          'error' => $e->getMessage()
        )
      );
      return $this->send_fail($e->getMessage());
    }
  }

  public function ajax_update_affiliate_settings() {
    $affiliate_id = $_POST["affiliate_id"];
    $affiliate_enabled = $_POST["affiliate_enabled"];

    update_option(
      'optinengine_affiliate_id',
      $affiliate_id
    );

    update_option(
      'optinengine_affiliate_enabled',
      $affiliate_enabled
    );
  }

  private function stack_to_array($entry) {
    return $entry["function"].':'.$entry["line"].PHP_EOL;
  }

  private function write_log($args) {
    try {
      $enabled = get_option('optinengine_logging_enabled', '0') == "1";
      if ($enabled) {
        /*
        $args['stack'] = array_map(
          array($this, "stack_to_array"), debug_backtrace()
        );
        */
        $args['datetime'] = date("Y-m-d H:i:s");
        WP_Logging::add(__FUNCTION__, json_encode($args));
      }
    } catch (Exception $e) {}
  }

  public function ajax_update_logging_settings() {
    $enabled = $_POST["logging_enabled"];
    update_option(
      'optinengine_logging_enabled',
      $enabled
    );
  }

  private function log_to_json($log) {
    return json_decode($log->post_content);
  }

  public function download_logs() {
    global $pagenow;
    if ($pagenow != 'tools.php' ||
      current_user_can('export') == false || 
      isset($_GET['action']) == false || 
      $_GET['action'] != 'optinengine-download-logs') {
      return;
    }

    header("Content-Disposition: attachment; filename=optinengine-logs.json");
    header("Pragma: no-cache");
    header("Expires: 0");

    $logs = WP_Logging::get_all_logs();

    if ($logs) {
      $json_logs = array_map(
        array($this, "log_to_json"),
        $logs->posts
      );

      echo json_encode(Array(
        'logs' => $json_logs
      ));
    }
    exit();
  }

  private function check_wpdb_error() {
    global $wpdb;
    if ($wpdb->last_error) {
      $this->write_log(
        Array(
          'function' => __FUNCTION__,
          'message' => 'Error running query',
          'error' => $wpdb->last_error
        )
      );
    }
  }

  public function __clone() {
    _doing_it_wrong(__FUNCTION__, __('Cheatin&#8217; huh?'), $this->parent->_version);
  }

  public function __wakeup() {
    _doing_it_wrong(__FUNCTION__, __('Cheatin&#8217; huh?'), $this->parent->_version);
  }
}

OptinEngineLite::instance(__FILE__);