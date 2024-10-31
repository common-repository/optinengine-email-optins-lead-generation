<?php

class Request
{
  public $auth = null;
  public $headers = array();

  function set_auth($auth) {
    $this->auth = $auth;
  }

  function add_header($name, $value) {
    $this->headers[] = $name . ': ' . $value;
  }

  function send($url, $is_post, $fields, $json) {
    // open connection
    $ch = curl_init();

    // set the url, number of POST vars, POST data
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_HEADER, true);

    if (isset($this->auth)) {
      curl_setopt($ch, CURLOPT_USERPWD, $this->auth);
      curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    }

    if ($is_post) {
      if ($fields) {
        $fields_string = '';
        foreach($fields as $key=>$value) {
          $fields_string .= $key.'='.urlencode($value).'&';
        }
        $fields_string = rtrim($fields_string,'&');
        curl_setopt($ch, CURLOPT_POST, count($fields));
        curl_setopt($ch, CURLOPT_POSTFIELDS, $fields_string);
      }

      else if ($json) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, $json);
        curl_setopt($ch, CURLOPT_HTTPHEADER, array(
          'Content-Type: application/json',
          'Content-Length: ' . strlen($json))
        );
      }
    }

    // add any headers
    if (sizeof($this->headers) > 0) {
      curl_setopt($ch, CURLOPT_HTTPHEADER, $this->headers);
    }

    // execute post
    $response = curl_exec($ch);
    $httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    $header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    $header = substr($response, 0, $header_size);
    $body = substr($response, $header_size);

    curl_close($ch);
    return (object) array(
      'code' => $httpcode,
      'body' => $body,
      'json' => json_decode($body)
    );
  }

  function post_fields($url, $fields) {
    return $this->send($url, true, $fields, null);
  }

  function post_json($url, $data) {
    return $this->send($url, true, null, json_encode($data));
  }

  function get($url) {
    return $this->send($url, false, null, null);
  }
}

?>