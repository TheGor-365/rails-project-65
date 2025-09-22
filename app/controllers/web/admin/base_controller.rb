# frozen_string_literal: true

module Web
  module Admin
    class BaseController < ApplicationController
      before_action :require_login
      before_action :authorize_admin!

      private

      def require_login
        return if signed_in?

        redirect_to root_path, alert: t('app.errors.login_required')
      end

      def authorize_admin!
        authorize :admin, :access?
      end
    end
  end
end
