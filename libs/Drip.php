<?php

if (!class_exists('Request')) {
  require_once(plugin_dir_path(__FILE__) . "Request.php");
}

class Drip
{
  public $account_id = null;
  public $api_key = null;

  function _create_request() {
    if (!isset($this->account_id) || !isset($this->api_key)) {
      throw new Exception('Set auth details first');
    }
    $request = new Request();
    $request->set_auth($this->api_key . ":");
    return $request;
  }

  function _api_url() {
    return 'https://api.getdrip.com/v2/' . $this->account_id;
  }

  function _get($path) {
    $request = $this->_create_request();
    return $request->get($this->_api_url() . $path);
  }

  function _post($path, $data) {
    $request = $this->_create_request();
    return $request->post_json($this->_api_url() . $path, $data);
  }

  function set_auth($account_id, $api_key) {
    $this->account_id = $account_id;
    $this->api_key = $api_key;
  }

  function get_lists() {
    $res = $this->_get('/campaigns');
    if ($res->code != 200) {
      throw new Exception('Unable to verify Drip account id/api key');
    }
    $lists = $res->json->campaigns;
    $result = array();
    foreach ($lists as $list) {
      $result[] = (object) array(
        'id' => sanitize_text_field($list->id),
        'name' => sanitize_text_field($list->name),
        'subscribers' => sanitize_text_field($list->active_subscriber_count)
      );
    }
    return $result;
  }

  function add_lead($list_id, $ip, $email, $name, $last_name, $disable_double_optin) {
    $full_name = $name;

    if ($last_name && strlen($last_name)) {
      $full_name = $name . ' ' . $last_name;
    }

    $data = array(
      'subscribers' => Array(
        Array(
          'email' => $email,
          'ip_address' => $ip,
          'custom_fields' => array(
            'name' => $full_name
          ),
          'double_optin' => !$disable_double_optin
        )
      )
    );

    return $this->_post('/campaigns/' . $list_id . '/subscribers', $data);
  }

  function auth() {
    $this->get_lists();
  }
}

?>