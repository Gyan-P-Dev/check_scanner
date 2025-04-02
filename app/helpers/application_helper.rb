module ApplicationHelper
  def nav_link_class(controller, action = nil)
    if action
      params[:controller] == controller && params[:action] == action ? "nav-link active" : "nav-link"
    else
      params[:controller] == controller && params[:action] != "new" ? "nav-link active" : "nav-link"
    end
  end
end
