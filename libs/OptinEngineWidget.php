<?php

class OptinEngineWidget extends WP_Widget {

  function __construct(){
    $options = array('description' => esc_html__( 'OptinEngine, please configure all the settings in OptinEngine settings page', 'OptinEngine'));
    parent::__construct(false, $name = 'OptinEngine', $options);
  }

  function form($instance) {
    $instance = wp_parse_args(
      (array) $instance,
      array(
        'title' => esc_html__('Subscribe', 'OptinEngine'),
        'promo_id' => ''
      )
    );

    $title = $instance['title'];
    $saved_promo_id = $instance['promo_id'];

    printf(
      '<p>
        <label for="%1$s">%2$s: </label>
        <input class="widefat" id="%1$s" name="%4$s" type="text" value="%3$s" />
      </p>',
      esc_attr($this->get_field_id('title')),
      esc_html__('Title', 'OptinEngine'),
      esc_attr($title),
      esc_attr($this->get_field_name('title'))
    );

    $widget_optins = Array();
    $promos = OptinEngineLite::instance(null)->get_all_promos();
    $options = '';
    $options .= sprintf(
      '<option value="0" %1$s>Select an optin</option>',
      selected(0, $saved_promo_id, false)
    );
    foreach ($promos as &$promo) {
      if ($promo->promoType != 'widget') {
        continue;
      }
      $options .= sprintf(
        '<option value="%1$s" %2$s>%3$s</option>',
        esc_attr($promo->id),
        selected($promo->id, $saved_promo_id, false),
        esc_html($promo->name)
      );
    }

    printf(
      '<p>
        <label for="%1$s">%2$s: </label>
        <select class="widefat" id="%1$s" name="%4$s" type="text">%5$s</select>
      </p>',
      esc_attr($this->get_field_id('promo_id')),
      esc_html__('Select Optin', 'OptinEngine'),
      esc_attr($title),
      esc_attr($this->get_field_name('promo_id')),
      $options
    );
  }

  function update($new_instance, $old_instance) {
    $instance = array();
    $instance['title'] = sanitize_text_field($new_instance['title']);
    $instance['promo_id'] = sanitize_text_field($new_instance['promo_id']);
    return $instance;
  }

  function widget($args, $instance) {
    extract($args);

    if (isset($instance['title'])) {
      $title = apply_filters('widget_title', $instance['title']);
    } else {
      $title = 'Subscribe';
    }

    echo $before_widget;
    echo '<div class="widget-text">';

    if ($title) {
      echo $before_title . $title . $after_title;
    }

    if (isset($instance['promo_id'])) {
      $promo_id = $instance['promo_id'];
      if ($promo_id) {
        echo do_shortcode('[optinengine_promo promo_id="'.$promo_id.'"]');
      }
    }

    echo '</div>';
    echo $after_widget;
  }
}

?>