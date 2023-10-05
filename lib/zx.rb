# frozen_string_literal: true

module Zx
end

require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.setup
loader.eager_load
