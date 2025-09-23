# frozen_string_literal: true

module Web
  module Admin
    class BaseController < ApplicationController
      before_action :authenticate_admin!

      private

      def authenticate_admin!
        return redirect_to(root_path, alert: t('flash.auth.sign_in')) unless signed_in?
        return if current_user.admin?
        redirect_to root_path, alert: t('flash.auth.no_rights')
      end
    end
  end
end
