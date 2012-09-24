require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/template')

describe Template do
  def config_file
    File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'examples', 'config', 'template.rb'))
  end

  let(:api_options) { { :config => config_file } }

  it 'renders haml template with default haml layout' do
    with_api(Template, api_options) do
      get_request(:path => '/') do |c|
        c.response.should =~ %r{<li><a href="/joke">Tell me a joke</a></li>}
      end
    end
  end

  it 'renders haml template from string with default haml layout' do
    with_api(Template, api_options) do
      get_request(:path => '/haml_str') do |c|
        c.response.should =~ %r{<h1>Header</h1>}
      end
    end
  end

  it 'renders a markdown template with default haml layout' do
    with_api(Template, api_options) do
      get_request(:path => '/joke') do |c|
        c.response.should =~ %r{<code>Arr, I dunno matey -- but it is driving me nuts!\s*</code>}m
      end
    end
  end

  it 'lets me specify an alternate layout engine' do
    with_api(Template, api_options) do
      get_request(:path => '/erb_me') do |c|
        c.response.should =~ %r{I AM ERB</h1>}m
      end
    end
  end

  it 'accepts local variables' do
    with_api(Template, api_options) do
      get_request(:path => '/erb_me') do |c|
        c.response.should =~ %r{<title>HERE IS A JOKE</title>}m
      end
    end
  end

  describe 'On a missing template' do
    it 'raises an explanatory 500 error' do
      with_api(Template, api_options) do
        get_request(:path => '/oops') do |c|
          c.response.should =~ %r{^\[:error, "Template no_such_template not found in .*examples/views for haml"\]$}
          c.response_header.status.should == 500
        end
      end
    end
  end
end
