module ApplicationHelper
  def title(page_title)
    base_title = "<%%= @site_title %>" 
    if page_title.empty?
      content_for(:title) { base_title }
    else
      content_for(:title) { page_title + " - " + base_title }
    end
  end
end
