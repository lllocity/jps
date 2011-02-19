<?php
/*
Plugin Name: Related Link Categories 
Plugin URI: http://example.com
Description: short desc
Version: 0.1
Author: lllocity
Author URI: http://example.com

*/

/*  Copyright 2010  lllocity <lllocity@example.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301, USA.
*/

class Related_Link_Categories extends WP_Widget {
    function Related_Link_Categories() {
        $widget_opts = array();
        $ctrl_opts   = array();

        $this->WP_Widget('related_link_categories', __('Related Link Categories'), $widget_opts, $ctrl_opts);
    }

    function form($instance) {
        $instance = wp_parse_args( (array) $instance, array( 'title' => '' ) );
        $title = strip_tags($instance['title']);
?>
            <p><label for="<?php echo $this->get_field_id('title'); ?>"><?php _e('Title:'); ?></label> <input class="widefat" id="<?php echo $this->get_field_id('title'); ?>" name="<?php echo $this->get_field_name('title'); ?>" type="text" value="<?php echo esc_attr($title); ?>" /></p>
<?php
    }

    function update($new_instance, $old_instance) {
        $instance = $old_instance;
        $instance['title'] = strip_tags($new_instance['title']);

        return $instance;
    }

    function widget($args, $instance) {
        global $wp_query, $wpdb;
        extract($args, EXTR_SKIP);

        // -- get settings
        $show_title = isset($instance['title']) ? $instance['title'] : '';

        // -- get slug from request
        $categoryname = $wp_query->query_vars['cat_name'];

        // -- get related link ids from slug;
        $query_format  = "SELECT r.object_id FROM %sterm_relationships r ";
        $query_format .= "LEFT JOIN %sterms t ON t.term_id = r.term_taxonomy_id ";
        $query_format .= "WHERE t.slug = '%s';";
        $query = sprintf($query_format, $wpdb->prefix, $wpdb->prefix, $categoryname);
        $link_ids = $wpdb->get_results($query);

        // -- get slug of related categories from link ids
        echo $before_widget;
        if ($link_ids) {
            $ary_link_ids = array();
            foreach ($link_ids as $id) {
                array_push($ary_link_ids, $id->object_id);
            }
            $query_format  = "SELECT DISTINCT t.term_id, t.slug FROM %sterm_relationships r ";
            $query_format .= "LEFT JOIN %sterms t ON r.term_taxonomy_id = t.term_id ";
            $query_format .= "LEFT JOIN %sterm_taxonomy x ON t.term_id = x.term_id ";
            $query_format .= "WHERE r.object_id IN (%s) AND t.slug != '%s' AND x.taxonomy = '%s'";

            $query = sprintf($query_format, $wpdb->prefix, $wpdb->prefix, $wpdb->prefix, implode(',', $ary_link_ids), $categoryname, 'link_category');
            $slugs = $wpdb->get_results($query);
            if ($slugs) {
                echo sprintf("%s%s%s\n", $before_title, $show_title, $after_title);
                echo sprintf("<ul class='%s'>\n", 'related_categories');
                foreach ($slugs as $slug) {
                    echo sprintf("<li><a href='%s'>%s (%d)</a></li>\n", $slug->slug, $slug->slug, get_term($slug->term_id, 'link_category')->count);
                }
                echo "</ul>\n";
            }
        }
        echo $after_widget;
    }
}

function Related_Link_CategoriesInit() {
    register_widget('Related_Link_Categories');
}

add_action('widgets_init', 'Related_Link_CategoriesInit');

?>
