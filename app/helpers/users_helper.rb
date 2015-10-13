module UsersHelper
	def errors_for(model, attribute)
		if model.errors[attribute].present?
			content_tag :p, :class => 'error-message' do
			  model.errors[attribute].join(", ").titleize
			end
		end
	end
end