<?php

if (!class_exists('Request')) {
  require_once(plugin_dir_path(__FILE__) . "Request.php");
}

class ActiveCampaign
{
  public $api_url = null;
  public $api_key = null;

  function _create_request() {
    if (!isset($this->api_url) || !isset($this->api_key)) {
      throw new Exception('Set auth details first');
    }
    $request = new Request();
    $request->set_auth($this->api_key . ":");
    return $request;
  }

  function _api_url() {
    return rtrim($this->api_url, '/') . '/';
  }

  function _get($path) {
    $request = $this->_create_request();
    return $request->get($this->_api_url() . $path);
  }

  function _post($path, $data) {
    $request = $this->_create_request();
    return $request->post_fields($this->_api_url() . $path, $data);
  }

  function set_auth($api_key, $api_url) {
    $this->api_url = $api_url;
    $this->api_key = $api_key;
  }

  function get_lists() {
    $res = $this->_get('admin/api.php?api_action=list_paginator&api_output=json&limit=1000&api_key='.$this->api_key);
    if ($res->code != 200 || $res->json->result_code != 1) {
      throw new Exception('Unable to load ActiveCampaign lists');
    }
    $lists = $res->json->rows;
    $result = array();
    foreach ($lists as $list) {
      $result[] = (object) array(
        'id' => sanitize_text_field($list->id),
        'name' => sanitize_text_field($list->name),
        'subscribers' => sanitize_text_field($list->subscribers_active)
      );
    }
    return $result;
  }

  function add_lead($list_id, $ip, $email, $name, $last_name, $disable_double_optin) {
    $data = array(
      'email' => $email,
      'first_name' => $name,
      'last_name' => $last_name,
      'p['.$list_id.']' => $list_id,
      'status['.$list_id.']' => 1,
    );

    $res = $this->_post('admin/api.php?api_action=contact_sync&api_output=json&api_key='.$this->api_key, $data);
    
    if ($res->code != 200 || $res->json->result_code != 1) {
      throw new Exception('Unable to load add contact to ActiveCampaign');
    }
    return $res;
  }

  function auth() {
    try {
      $this->get_lists();
    } catch (Exception $e) {
      throw new Exception('Unable to verify ActiveCampaign url/key');
    }
  }
}

?>