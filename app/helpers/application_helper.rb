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
end
