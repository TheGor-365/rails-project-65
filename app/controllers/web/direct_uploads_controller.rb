# frozen_string_literal: true

module Web
  class DirectUploadsController < ApplicationController
    def create
      head :not_found
    end
  end
end
