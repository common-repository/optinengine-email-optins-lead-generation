<?php

if (!class_exists('Request')) {
  require_once(plugin_dir_path(__FILE__) . "Request.php");
}

class MailChimp
{
  public $account_name = null;
  public $api_key = null;

  function _create_request() {
    if (!isset($this->account_name) || !isset($this->api_key)) {
      throw new Exception('Set auth details first');
    }
    $request = new Request();
    $request->set_auth($this->account_name . ":" . $this->api_key);
    return $request;
  }

  function _api_url() {
    $parts = explode("-", $this->api_key);
    if (count($parts) < 2) {
      throw new Exception('API key format is invalid');
    }
    return 'https://' . $parts[1] . '.api.mailchimp.com/3.0';
  }

  function _get($path) {
    $request = $this->_create_request();
    return $request->get($this->_api_url() . $path);
  }

  function _post($path, $data) {
    $request = $this->_create_request();
    return $request->post_json($this->_api_url() . $path, $data);
  }

  function set_auth($account_name, $api_key) {
    $this->account_name = $account_name;
    $this->api_key = $api_key;
  }

  function get_lists() {
    $res = $this->_get('/lists');
    if ($res->code != 200) {
      throw new Exception('Unable to verify MailChimp account/api key');
    }
    $lists = $res->json->lists;
    $result = array();
    foreach ($lists as $list) {
      $result[] = (object) array(
        'id' => sanitize_text_field($list->id),
        'name' => sanitize_text_field($list->name),
        'subscribers' => sanitize_text_field($list->stats->member_count)
      );
    }
    return $result;
  }

  function add_lead($list_id, $ip, $email, $name, $last_name, $disable_double_optin) {
    $status = $disable_double_optin === true ? 'subscribed' : 'pending';
    $data = array(
      'email_address' => $email,
      'ip_signup' => $ip,
      'merge_fields' => array(
        'FNAME' => $name,
        'LNAME' => $last_name
      ),
      'status' => $status
    );

    return $this->_post('/lists/' . $list_id . '/members', $data);
  }
}

?>