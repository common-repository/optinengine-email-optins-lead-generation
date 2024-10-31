<?php


if (!class_exists('CS_REST_General')) {
  require_once(plugin_dir_path(__FILE__) . "campaignmonitor/csrest_general.php");
}

if (!class_exists('CS_REST_Clients')) {
  require_once(plugin_dir_path(__FILE__) . "campaignmonitor/csrest_clients.php");
}

if (!class_exists('CS_REST_Lists')) {
  require_once(plugin_dir_path(__FILE__) . "campaignmonitor/csrest_lists.php");
}

if (!class_exists('CS_REST_Subscribers')) {
  require_once(plugin_dir_path(__FILE__) . "campaignmonitor/csrest_subscribers.php");
}

class CampaignMonitor
{
  public $api_key = null;

  function set_auth($api_key) {
    $this->api_key = $api_key;
  }

  function get_lists() {
    $auth = array('api_key' => $this->api_key);
    $wrap = new CS_REST_General($auth);
    $clients = $wrap->get_clients();
    
    if (!$clients->was_successful()) {
      throw new Exception('Unable to load Campaign Monitor clients');
    }

    $result = array();

    foreach ($clients->response as $client) {
      $clients_api = new CS_REST_Clients($client->ClientID, $auth);
      $lists_data = $clients_api->get_lists();

      if (!$lists_data->was_successful()) {
        throw new Exception('Unable to load Campaign Monitor client lists');
      }

      foreach ($lists_data->response as $list => $single_list) {
        $wrap_stats = new CS_REST_Lists($single_list->ListID, $auth);
        $result_stats = $wrap_stats->get_stats();

        $result[] = (object) array(
          'id' => sanitize_text_field($single_list->ListID),
          'name' => sanitize_text_field($single_list->Name),
          'subscribers' => sanitize_text_field($result_stats->response->TotalActiveSubscribers)
        );
      }
    }

    return $result;
  }

  function add_lead($list_id, $ip, $email, $name, $last_name, $disable_double_optin) {
    $auth = array('api_key' => $this->api_key);
    $subscribers = new CS_REST_Subscribers($list_id, $auth);
    $is_subscribed = $subscribers->get($email);

    if ($is_subscribed->was_successful()) {
      // already subscribed
      return;
    }

    $full_name = $name;

    if ($last_name && strlen($last_name)) {
      $full_name = $name . ' ' . $last_name;
    }

    $result = $subscribers->add(array(
      'EmailAddress' => sanitize_email($email),
      'Name' => sanitize_text_field($last_name),
      'Resubscribe' => false,
    ));

    if (!$result->was_successful()) {
      throw Exception("Unable to add Campaign Monitor lead");
    }

    return $result;
  }

  function auth() {
    $auth = array('api_key' => $this->api_key);
    $wrap = new CS_REST_General($auth);
    $result = $wrap->get_clients();
    if (!$result->was_successful()) {
      throw new Exception('Unable to verify Campaign Monitor api key');
    }
  }
}

?>