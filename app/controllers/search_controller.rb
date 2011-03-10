class SearchController < ApplicationController
  include DC::Search::Controller

  before_filter :bouncer if Rails.env.staging?
  before_filter :login_required, :only => [:preview]

  FIELD_STRIP = /\S+:\s*/

  def documents
    perform_search :include_facets => params[:include_facets]
    results = {:query => @query, :documents => @documents}
    results[:facets] = @query.facets if params[:include_facets]
    results[:source_document] = @source_document if params.include? :include_source_document
    respond_to do |format|
      format.json do
        json results
      end
    end
  end
  
  def embed
    groups = params[:options].match /p-(\d+)-per-(\d+)-order-(\w+)/
    _, params[:page], params[:per_page], params[:order] = *groups
    perform_search :include_facets => params[:include_facets]
    results             = {:query => @query, :documents => @documents}
    results[:query]     = params[:q]
    results[:total]     = @query.total
    results[:page]      = @query.page
    results[:per_page]  = @query.per_page
    results[:documents] = @documents.map {|d| d.canonical(API_OPTIONS) }
    js                  = "dc.loadSearchEmbedCallback(#{results.to_json});"
    cache_page js
    render :js => js
  end
  
  def restricted_count
    params[:q] += " filter:restricted"
    perform_search
    restricted_count = @query.total
    counts = {
      :restricted_count => restricted_count
    }
    json counts
  end

  def facets
    perform_search :exclude_documents => true,
                   :include_facets => true
    results = {:query => @query, :facets => @query.facets}
    json results
  end

  def preview
    @query   = params[:query]
    @slug    = params[:slug]
    @options = params[:options]
  end

  def loader
    render :action => 'loader', :content_type => :js
  end
  
end