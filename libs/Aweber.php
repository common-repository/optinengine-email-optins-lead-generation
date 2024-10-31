<?php

if (!class_exists('Request')) {
  require_once(plugin_dir_path(__FILE__) . "Request.php");
}

if (!class_exists( 'AWeberAPI' ) ) {
  require_once(plugin_dir_path(__FILE__) . 'aweber/aweber_api.php' );
}

class Aweber
{
  public $auth = null;

  function _get_account() {
    $aweber = new AWeberAPI(
      $this->auth->consumer_key,
      $this->auth->consumer_secret
    );

    if (!$aweber) {
      throw new Exception('Error creating Aweber api');
    }

    return $aweber->getAccount(
      $this->auth->access_key,
      $this->auth->access_secret
    );
  }

  function set_auth($auth) {
    $this->auth = $auth;
  }

  function get_lists() {
    try {
      $account = $this->_get_account();

      if (!$account) {
        throw new Exception('Unable to load Aweber account');
      }

      $results = array();

      foreach ($account->lists as $list) {
        $results[] = (object) Array(
          'id' => sanitize_text_field($list->id),
          'name' => sanitize_text_field($list->name),
          'subscribers' => sanitize_text_field($list->total_subscribers)
        );
      }

      return $results;
    } catch (Exception $e) {
      throw new Exception('Unable to load email lists from Aweber');
    }
  }

  function add_lead($list_id, $ip, $email, $name, $last_name, $disable_double_optin) {
    try {
      $account = $this->_get_account();

      if (!$account) {
        throw new Exception('Unable to load Aweber account');
      }

      $full_name = $name;

      if ($last_name && strlen($last_name)) {
        $full_name = $name . ' ' . $last_name;
      }

      $list_url = "/accounts/{$account->id}/lists/{$list_id}";
      $list = $account->loadFromUrl($list_url);

      $new_subscriber = $list->subscribers->create(
        array(
          'email' => $email,
          'name'  => $full_name,
          'ip_address' => $ip
        )
      );

      return $new_subscriber;
    } catch (Exception $e) {
      throw new Exception('Error adding lead to Aweber');
    }
  }

  function auth($api_key) {
    $auth = AWeberAPI::getDataFromAweberID($api_key);

    if (!(is_array($auth) && 4 === count($auth))) {
      throw new Exception('Invalid authorization code, please try again');
    }

    list($consumer_key, $consumer_secret, $access_key, $access_secret) = $auth;

    return (object) array(
      'api_key' => sanitize_text_field( $api_key ),
      'consumer_key' => sanitize_text_field( $consumer_key ),
      'consumer_secret' => sanitize_text_field( $consumer_secret ),
      'access_key' => sanitize_text_field( $access_key ),
      'access_secret' => sanitize_text_field( $access_secret ),
    );
  }
}

?>