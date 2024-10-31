<?php

if (!class_exists('Request')) {
  require_once(plugin_dir_path(__FILE__) . "Request.php");
}

class Intercom
{
  public $api_key = null;

  function set_auth($api_key) {
    $this->api_key = $api_key;
  }

  function _create_request() {
    if (!isset($this->api_key)) {
      throw new Exception('Set auth details first');
    }
    $request = new Request();
    $request->add_header('Authorization', 'Bearer ' . $this->api_key);
    $request->add_header('Content-Type', 'application/json');
    $request->add_header('Accept', 'application/json');
    return $request;
  }

  function _api_url() {
    return 'https://api.intercom.io';
  }

  function _get($path) {
    $request = $this->_create_request();
    return $request->get($this->_api_url() . $path);
  }

  function _post($path, $data) {
    $request = $this->_create_request();
    return $request->post_json($this->_api_url() . $path, $data);
  }

  function get_lists() {
    $result = array();
    $result[] = (object) array(
      'id' => "x_all_people",
      'name' => "Intercom People",
      'subscribers' => -1
    );
    return $result;
  }

  function add_lead($list_id, $ip, $email, $name, $last_name, $disable_double_optin) {

    $full_name = $name;

    if ($last_name && strlen($last_name)) {
      $full_name = $name . ' ' . $last_name;
    }

    return $this->_post("/contacts", Array(
      "email" => $email,
      "last_seen_ip" => $ip,
      "name" => $full_name
    ));
  }

  function auth() {
    try {
      $tags = $this->_get("/tags");
      if ($tags->code != 200) {
        throw new Error();
      }
    } catch (Exception $e) {
      throw new Exception("Invalid Intercom access token");
    }
  }
}

?>