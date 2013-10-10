#encoding: utf-8
module ApplicationHelper
  def horizontal_form_for(object, *args, &block)
    options = args.extract_options!

    html_options = options[:html] || {}
    html_options[:class] = "#{html_options[:class]} form-horizontal"

    options[:html] = html_options
    simple_form_for(object, *(args << options), &block)
  end

  def inline_form_for(object, *args, &block)
    options = args.extract_options!

    html_options = options[:html] || {}
    html_options[:class] = "#{html_options[:class]} form-inline"

    options[:html] = html_options
    options[:wrapper] = :default
    simple_form_for(object, *(args << options), &block)
  end

  def submit_ladda_button(txt, options = {})
    button_tag txt, :class => ["ladda ladda-button btn btn-primary"]<<options[:class], :type => "submit", data: { style: 'expand-right' }
  end

  def back_to_project
    link_to '← back to project', project_path(@project)
  end
end
