<?php

if (!class_exists('Request')) {
  require_once(plugin_dir_path(__FILE__) . "Request.php");
}

class GetResponse
{
  public $api_key = null;

  function _create_request() {
    if (!isset($this->api_key)) {
      throw new Exception('Set auth details first');
    }
    $request = new Request();
    $request->add_header('X-Auth-Token', 'api-key ' . $this->api_key);
    $request->add_header('Content-Type', 'application/json');
    return $request;
  }

  function _api_url() {
    return 'https://api.getresponse.com/v3';
  }

  function _get($path) {
    $request = $this->_create_request();
    return $request->get($this->_api_url() . $path);
  }

  function _post($path, $data) {
    $request = $this->_create_request();
    return $request->post_json($this->_api_url() . $path, $data);
  }

  function set_auth($api_key) {
    $this->api_key = $api_key;
  }

  function get_lists() {
    $res = $this->_get('/campaigns?page=1&perPage=100&sort[name]=asc');
    if ($res->code != 200) {
      throw new Exception('Unable to verify GetResponse api key');
    }
    $lists = $res->json;
    $result = array();
    foreach ($res->json as $list) {
      $result[] = (object) array(
        'id' => sanitize_text_field($list->campaignId),
        'name' => sanitize_text_field($list->name),
        'subscribers' => -1
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
      'email' => $email,
      'name' => $full_name,
      'ipAddress' => $ip,
      'campaign' => array(
        'campaignId' => $list_id
      )
    );

    return $this->_post('/contacts', $data);
  }
}

?>