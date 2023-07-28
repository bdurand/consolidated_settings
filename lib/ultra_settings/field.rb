# frozen_string_literal: true

module UltraSettings
  # Definition for a field on a configuration.
  class Field
    attr_reader :name
    attr_reader :type
    attr_reader :description
    attr_reader :default
    attr_reader :default_if
    attr_reader :env_var
    attr_reader :runtime_setting
    attr_reader :yaml_key

    # @param name [String, Symbol] The name of the field.
    # @param type [Symbol] The type of the field.
    # @param description [String] The description of the field.
    # @param default [Object] The default value of the field.
    # @param default_if [Proc] A proc that returns true if the default value should be used.
    # @param env_var [String, Symbol] The name of the environment variable to use for the field.
    # @param runtime_setting [String, Symbol] The name of the setting to use for the field.
    # @param yaml_key [String, Symbol] The name of the YAML key to use for the field.
    def initialize(
      name:,
      type: :string,
      description: nil,
      default: nil,
      default_if: nil,
      env_var: nil,
      runtime_setting: nil,
      yaml_key: nil,
      static: false
    )
      @name = name.to_s.freeze
      @type = type.to_sym
      @description = description&.to_s&.freeze
      @default = Coerce.coerce_value(default, @type).freeze
      @default_if = default_if
      @env_var = env_var&.to_s&.freeze
      @runtime_setting = runtime_setting&.to_s&.freeze
      @yaml_key = yaml_key&.to_s&.freeze
      @static = !!static
    end

    # Get the value for the field from the passed in state.
    #
    # @param env [#[]] The environment variables.
    # @param settings [#[]] The runtime settings.
    # @param yaml_config [#[]] The YAML configuration.
    def value(env: nil, settings: nil, yaml_config: nil)
      fetch_value_and_source(env: env, settings: settings, yaml_config: yaml_config).first
    end

    # Get the source for the field from the passed in state.
    #
    # @param env [Hash] The environment variables.
    # @param settings [Hash] The runtime settings.
    # @param yaml_config [Hash] The YAML configuration.
    # @return [Symbol, nil] The source of the value (:env, :settings, or :yaml).
    def source(env: nil, settings: nil, yaml_config: nil)
      fetch_value_and_source(env: env, settings: settings, yaml_config: yaml_config).last
    end

    # Coerce the passed in value to the type of the field.
    #
    # @param value [Object] The value to coerce.
    # @return [Object] The coerced value.
    def coerce(value)
      Coerce.coerce_value(value, @type)
    end

    # Returns true if the field is static.
    #
    # @return [Boolean]
    def static?
      @static
    end

    private

    def fetch_value_and_source(env:, settings:, yaml_config:)
      source = nil

      value = env[env_var] if env && env_var
      value = nil if value == ""
      if value.nil?
        value = settings[runtime_setting] if settings && runtime_setting
        value = nil if value == ""
        if value.nil?
          value = yaml_value(yaml_config)
          value = nil if value == ""
          source = :yaml unless value.nil?
        else
          source = :settings
        end
      else
        source = :env
      end

      value = coerce(value).freeze

      [value, source]
    end

    def yaml_value(yaml_config)
      return nil unless yaml_config && yaml_key

      yaml_config[yaml_key]
    end
  end
end
