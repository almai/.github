#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$script_dir" rev-parse --show-toplevel)"
if ! command -v ruby >/dev/null 2>&1; then
  echo "Error: Ruby is required." >&2
  exit 2
fi

if [[ $# -eq 0 ]]; then
  set -- "$repo_root/.github/ISSUE_TEMPLATE"
fi

files=()
for target in "$@"; do
  if [[ -d "$target" ]]; then
    shopt -s nullglob
    for file in "$target"/*.yml; do
      [[ -f "$file" ]] && files+=("$file")
    done
    shopt -u nullglob
  else
    files+=("$target")
  fi
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "Error: no .yml issue forms found." >&2
  exit 1
fi

ruby - "${files[@]}" <<'RUBY'
require "yaml"

TOP_LEVEL_KEYS = %w[name description title labels assignees type projects body].freeze
FORM_TYPES = %w[markdown input textarea dropdown checkboxes upload].freeze
FORBIDDEN_KEYWORDS = %w[y yes n no true false on off].freeze
STRING_VALUE_KEYS = %w[name description title labels assignees type projects id label placeholder value render options].freeze
SENSITIVE_LABEL_TERMS = /\b(?:password|passcode|secret|token|credential|private[ -]key|api[ -]key)\b/i

def nonblank_string?(value)
  value.is_a?(String) && !value.strip.empty?
end

def validate_string(value, path, errors)
  errors << "#{path} must be a nonblank string" unless nonblank_string?(value)
end

def validate_mapping(mapping, allowed, path, errors)
  unless mapping.is_a?(Hash)
    errors << "#{path} must be a mapping"
    return false
  end

  mapping.each_key do |key|
    unless key.is_a?(String)
      errors << "#{path} has a key that YAML parsed as a non-string; quote boolean-like keys"
      next
    end
    if FORBIDDEN_KEYWORDS.include?(key.downcase)
      errors << "#{path} uses forbidden boolean-like key #{key.inspect}"
    end
    errors << "#{path} contains unsupported key #{key.inspect}" unless allowed.include?(key)
  end
  true
end

def find_duplicate_yaml_keys(node, errors, path)
  case node
  when Psych::Nodes::Document, Psych::Nodes::Stream
    node.children.each { |child| find_duplicate_yaml_keys(child, errors, path) }
  when Psych::Nodes::Mapping
    seen = {}
    node.children.each_slice(2) do |key_node, value_node|
      if key_node.is_a?(Psych::Nodes::Scalar)
        key = key_node.value
        errors << "duplicate YAML key #{key.inspect}" if seen.key?(key)
        seen[key] = true
      end
      find_duplicate_yaml_keys(key_node, errors, path)
      find_duplicate_yaml_keys(value_node, errors, path)
    end
  when Psych::Nodes::Sequence
    node.children.each { |child| find_duplicate_yaml_keys(child, errors, path) }
  end
end

def find_unquoted_boolean_strings(node, errors, context = nil)
  case node
  when Psych::Nodes::Document, Psych::Nodes::Stream
    node.children.each { |child| find_unquoted_boolean_strings(child, errors, context) }
  when Psych::Nodes::Mapping
    node.children.each_slice(2) do |key_node, value_node|
      key = key_node.is_a?(Psych::Nodes::Scalar) ? key_node.value : nil
      find_unquoted_boolean_strings(value_node, errors, key)
    end
  when Psych::Nodes::Sequence
    node.children.each { |child| find_unquoted_boolean_strings(child, errors, context) }
  when Psych::Nodes::Scalar
    boolean_word = FORBIDDEN_KEYWORDS.include?(node.value.downcase)
    if node.plain && boolean_word && STRING_VALUE_KEYS.include?(context)
      errors << "unquoted boolean-like string #{node.value.inspect} under #{context.inspect} must be quoted"
    end
  end
end

def validate_options(options, path, errors, reserved_none: false)
  unless options.is_a?(Array) && !options.empty?
    errors << "#{path} must be a nonempty array"
    return []
  end

  strings = []
  options.each_with_index do |option, index|
    if nonblank_string?(option)
      strings << option
      if reserved_none && option.strip.casecmp?("none")
        errors << "#{path}[#{index}] must not use the reserved option 'None'"
      end
    else
      errors << "#{path}[#{index}] must be a nonblank string; quote boolean-like or numeric choices"
    end
  end
  errors << "#{path} must contain unique options" unless strings.uniq.length == strings.length
  strings
end

def validate_form(file)
  errors = []
  unless file.end_with?(".yml")
    errors << "issue form filename must use the .yml extension"
    return errors
  end
  unless File.file?(file)
    errors << "file does not exist"
    return errors
  end

  begin
    syntax_tree = Psych.parse_file(file)
    if syntax_tree
      find_duplicate_yaml_keys(syntax_tree, errors, file)
      find_unquoted_boolean_strings(syntax_tree, errors)
    end
    form = YAML.safe_load_file(file, permitted_classes: [], aliases: false)
  rescue Psych::Exception => error
    errors << "invalid YAML: #{error.message.lines.first.strip}"
    return errors
  end

  unless validate_mapping(form, TOP_LEVEL_KEYS, "form", errors)
    return errors
  end

  %w[name description].each do |key|
    validate_string(form[key], key, errors)
  end
  if nonblank_string?(form["name"]) && form["name"].strip.length <= 3
    errors << "name must be longer than 3 characters"
  end
  %w[title type].each do |key|
    validate_string(form[key], key, errors) if form.key?(key)
  end
  %w[labels assignees projects].each do |key|
    next unless form.key?(key)
    value = form[key]
    values = value.is_a?(Array) ? value : [value]
    errors << "#{key} must be a string or an array of strings" unless value.is_a?(String) || value.is_a?(Array)
    values.each_with_index { |item, index| validate_string(item, "#{key}[#{index}]", errors) }
  end

  body = form["body"]
  unless body.is_a?(Array) && !body.empty?
    errors << "body must be a nonempty array"
    return errors
  end

  input_count = 0
  ids = {}
  labels = Hash.new { |hash, key| hash[key] = [] }
  body.each_with_index do |item, index|
    path = "body[#{index}]"
    unless item.is_a?(Hash)
      errors << "#{path} must be a mapping"
      next
    end
    validate_mapping(item, %w[type id attributes validations], path, errors)
    type = item["type"]
    unless type.is_a?(String) && FORM_TYPES.include?(type)
      errors << "#{path}.type must be one of: #{FORM_TYPES.join(', ')}"
      next
    end
    input_count += 1 unless type == "markdown"

    if item.key?("id")
      id = item["id"]
      if type == "markdown"
        errors << "#{path}.id is not supported for markdown elements"
      elsif !nonblank_string?(id) || id !~ /\A[a-zA-Z0-9_-]+\z/
        errors << "#{path}.id may contain only letters, numbers, hyphens, and underscores"
      elsif ids.key?(id)
        errors << "#{path}.id duplicates #{ids[id]}"
      else
        ids[id] = path
      end
    end

    attributes = item["attributes"]
    allowed_attributes = case type
      when "markdown" then %w[value]
      when "input" then %w[label description placeholder value]
      when "textarea" then %w[label description placeholder value render]
      when "dropdown" then %w[label description multiple options default]
      when "checkboxes" then %w[label description options]
      when "upload" then %w[label description]
    end
    next unless validate_mapping(attributes, allowed_attributes, "#{path}.attributes", errors)

    if type == "markdown"
      validate_string(attributes["value"], "#{path}.attributes.value", errors)
    else
      label = attributes["label"]
      validate_string(label, "#{path}.attributes.label", errors)
      if nonblank_string?(label)
        if label.match?(SENSITIVE_LABEL_TERMS)
          errors << "#{path}.attributes.label may solicit sensitive credentials; use a non-sensitive prompt"
        end
        labels[label.downcase.gsub(/[^\p{Alnum}]+/u, "-").gsub(/\A-+|-+\z/, "")] << {
          "label" => label, "id" => item["id"], "path" => "#{path}.attributes.label"
        }
      end
      %w[description placeholder value render].each do |key|
        validate_string(attributes[key], "#{path}.attributes.#{key}", errors) if attributes.key?(key)
      end

      if type == "dropdown"
        options = validate_options(attributes["options"], "#{path}.attributes.options", errors, reserved_none: true)
        if attributes.key?("multiple") && ![true, false].include?(attributes["multiple"])
          errors << "#{path}.attributes.multiple must be a boolean"
        end
        if attributes.key?("default")
          default = attributes["default"]
          if !default.is_a?(Integer) || default.negative? || default >= options.length
            errors << "#{path}.attributes.default must be a valid zero-based option index"
          end
          if options.any? { |option| %w[none n/a].include?(option.strip.downcase) }
            errors << "#{path}.attributes.default cannot be used with a None or n/a option"
          end
        end
      elsif type == "checkboxes"
        options = attributes["options"]
        unless options.is_a?(Array) && !options.empty?
          errors << "#{path}.attributes.options must be a nonempty array"
          options = []
        end
        options.each_with_index do |option, option_index|
          option_path = "#{path}.attributes.options[#{option_index}]"
          unless validate_mapping(option, %w[label required], option_path, errors)
            next
          end
          option_label = option["label"]
          validate_string(option_label, "#{option_path}.label", errors)
          if nonblank_string?(option_label)
            if option_label.match?(SENSITIVE_LABEL_TERMS)
              errors << "#{option_path}.label may solicit sensitive credentials; use a non-sensitive prompt"
            end
            labels[option_label.downcase.gsub(/[^\p{Alnum}]+/u, "-").gsub(/\A-+|-+\z/, "")] << {
              "label" => option_label, "id" => nil, "path" => "#{option_path}.label"
            }
          end
          if option.key?("required") && ![true, false].include?(option["required"])
            errors << "#{option_path}.required must be a boolean"
          end
        end
      end
    end

    validations = item["validations"]
    allowed_validations = case type
      when "input", "textarea" then %w[required min_length]
      when "dropdown", "upload" then %w[required]
      else []
    end
    next unless item.key?("validations")
    next unless validate_mapping(validations, allowed_validations, "#{path}.validations", errors)

    if validations.key?("required") && ![true, false].include?(validations["required"])
      errors << "#{path}.validations.required must be a boolean"
    end
    if validations.key?("min_length") &&
       (!validations["min_length"].is_a?(Integer) || validations["min_length"].negative?)
      errors << "#{path}.validations.min_length must be a nonnegative integer"
    end
  end

  errors << "body must contain at least one non-markdown input field" if input_count.zero?
  labels.each_value do |entries|
    next if entries.length < 2
    distinct_ids = entries.all? { |entry| nonblank_string?(entry["id"]) } &&
      entries.map { |entry| entry["id"] }.uniq.length == entries.length
    unless distinct_ids
      errors << "labels are duplicated or too similar: #{entries.map { |entry| entry["label"].inspect }.join(', ')}"
    end
  end
  errors
end

files = ARGV
failed = false
files.each do |file|
  errors = validate_form(file)
  if errors.empty?
    puts "OK: #{file}"
  else
    failed = true
    warn "ERROR: #{file}"
    errors.each { |error| warn "  - #{error}" }
  end
end
exit(failed ? 1 : 0)
RUBY
