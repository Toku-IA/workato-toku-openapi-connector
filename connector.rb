{
  title: 'Test custom OpenAPI',
  secure_tunnel: true,

  connection: {
    fields: [
      {
        name: 'gcp_bucket',
        label: 'Bucket',
        type: 'string',
        control_type: 'plain-text',
        default: 'api-registry-b7991275-bucket',
        hint: 'Shared GCS bucket. Public Workato schema: connector/public.json (raw per repo: <repo>/openapi.json).'
      },
      {
        name: 'gcp_object',
        label: 'Schema bucket object',
        type: 'string',
        control_type: 'plain-text',
        default: 'connector/public.json',
        hint: 'Full object path in the bucket (e.g. connector/public.json). Not a bare file name unless the object is at bucket root.'
      },
      {
        name: 'sa_private_token',
        label: 'Service Account Key',
        type: 'string',
        control_type: 'password',
        hint: 'JSON con la llave de la Service Account para autenticarse en GCP'
      },
      {
        name: 'auth_method',
        label: 'Authentication method',
        hint: 'Select an authentication method.',
        optional: false,
        control_type: 'select',
        extends_schema: true,
        options: [
          %w[Header header],
        ]
      },
      {
        name: 'base_url',
        label: 'Server URL',
        optional: false,
        control_type: 'url',
        hint: 'A URL to the target host or service, ' \
              'e.g. <b>https://app.example.com</b> or <b>https://example.com/app</b>. ' \
              'Relative endpoint paths from the OpenAPI document will be appended ' \
              'to the Server URL in order to construct the full endpoint URL.'
      }
    ],

    authorization: {
      type: 'multi',

      selected: lambda do |connection|
        connection['auth_method'] || 'header'
      end,

      options: {
        header: {
          type: 'custom_auth',

          fields: [
            {
              ngIf: '!(input.auth_headers == null || input.auth_headers == "")',
              name: 'auth_headers',
              label: 'Header authorization (Deprecated)',
              hint: 'Add custom auth headers, one per line, e.g. <b>X-API-Token: secret42</b> or ' \
                    '<b>Authorization: Bearer AbC123XyZ789uje4</b>',
              optional: false,
              type: 'string',
              control_type: 'text-area'
            },
            {
              ngIf: 'input.auth_headers == null || input.auth_headers == ""',
              name: 'auth_headers_key_value',
              label: 'Header authorization',
              control_type: 'key_value',
              empty_list_title: 'Does the application require additional headers?',
              empty_list_text: 'Refer to the API documentation and add ' \
                               'required headers.',
              item_label: 'Auth Headers',
              type: 'array',
              of: 'object',
              optional: false,
              properties: [
                { name: 'key', label: 'Header name' },
                { name: 'value', control_type: 'password' }
              ]
            },
            {
              name: 'advanced',
              label: 'Advanced settings',
              type: 'object',
              properties: [
                {
                  name: 'test_endpoint',
                  label: 'Test Request URL',
                  optional: true,
                  hint: 'Provide a relative URL to test the connection, e.g. <b>/user/profile</b>. ' \
                        'A GET request will be made to this endpoint to verify the connetion is valid.'
                },
                {
                  name: 'object_label_field',
                  label: 'Object name field',
                  hint: 'Select the field to use for the object names in the pick list.',
                  optional: true,
                  control_type: 'select',
                  options: [
                    %w[Summary summary],
                    %w[Operation\ ID operation_id],
                    %w[Description description]
                  ]
                },
                {
                  name: 'execute_operation_label_field',
                  label: 'Operation name field',
                  hint: 'Select the field to use for the operation names to execute in the pick list. ' \
                        'Defaults to object name field.',
                  optional: true,
                  control_type: 'select',
                  options: [
                    %w[Summary summary],
                    %w[Operation\ ID operation_id],
                    %w[Description description]
                  ]
                },
                {
                  ngIf: 'input.advanced.object_label_field == "summary" || ' \
                        'input.advanced.object_label_field == "operation_id" || ' \
                        'input.advanced.object_label_field == "description" || ' \
                        'input.advanced.execute_operation_label_field == "summary" || ' \
                        'input.advanced.execute_operation_label_field == "operation_id" || ' \
                        'input.advanced.execute_operation_label_field == "description"',
                  name: 'object_label_substitutions',
                  label: 'Object name substitutions',
                  hint: 'List of substitutions for object/operation names. ' \
                        'Only required if names need to be modified to improve ' \
                        'object/operation picker UX.',
                  optional: true,
                  type: 'array',
                  of: 'object',
                  list_mode: 'static',
                  item_label: 'Object name substitution',
                  add_item_label: 'Add substitution',
                  empty_list_text: 'Add object name substitutions to improve object picker UX.',
                  properties: [
                    {
                      name: 'pattern',
                      hint: 'Regular expression string, optionally including capture groups.',
                      optional: false
                    },
                    {
                      name: 'replacement',
                      hint: 'String replacing all occurrences of pattern. ' \
                            'It may contain back-references to the pattern’s capture groups of the ' \
                            'form &bsol;d, where d is a group number, or &bsol;k&lt;n&gt;, ' \
                            'where n is a group ' \
                            'name. If it is a double-quoted string, both back-references must be ' \
                            'preceded by an additional backslash. However, within replacement the ' \
                            'special match variables, such as &#36;&amp;, will not refer to the ' \
                            'current match.',
                      optional: false
                    }
                  ]
                },
                {
                  name: 'object_label_map',
                  label: 'Static object names',
                  hint: 'Specify object/operation names for API endpoints based the <b>operationId</b> ' \
                        'field. ' \
                        'Only required if the OpenAPI document doesn\'t provide user-friendly names ' \
                        'for individual API endpoints.',
                  optional: true,
                  control_type: 'key_value',
                  item_label: 'Object name',
                  add_item_label: 'Add object name',
                  empty_list_text: 'Add static object/operation names for API endpoints.',
                  type: 'array',
                  of: 'object',
                  properties: [
                    {
                      name: 'operation_id',
                      label: 'Operation ID',
                      hint: 'OperationID in the OpenAPI document, e.g. getuser. ' \
                            'These are unique, case-sensitive strings to ' \
                            'identify operations.'
                    },
                    {
                      name: 'label',
                      label: 'Display name',
                      hint: 'Name to display in object field.<br>For CRUD actions, this is typically ' \
                            'a simple object name, e.g. User, Account or Contact. ' \
                            '<br>For the \'Execute operation\' action, prefix the object name ' \
                            'with a verb, e.g. Archive user, Close ticket or Migrate account.'
                    }
                  ]
                },
                {
                  name: 'object_hint_field',
                  label: 'Object hint',
                  hint: 'Select the field to use for hint for the objects/operations in the pick list.',
                  optional: true,
                  control_type: 'select',
                  options: [
                    %w[Description description],
                    %w[Summary summary]
                  ]
                },
                {
                  name: 'object_hint_substitutions',
                  label: 'Object hint substitutions',
                  hint: 'List of substitutions for object hints. ' \
                        'Only required when Object hint field values ' \
                        'need to be modified to improve object picker UX.',
                  optional: true,
                  type: 'array',
                  of: 'object',
                  list_mode: 'static',
                  item_label: 'Object hint substitution',
                  add_item_label: 'Add substitution',
                  empty_list_text: 'Add object hint substitutions to improve object picker UX.',
                  properties: [
                    {
                      name: 'pattern',
                      hint: 'Regular expression string, optionally including capture groups.',
                      optional: false
                    },
                    {
                      name: 'replacement',
                      hint: 'String replacing all occurrences of pattern. ' \
                            'It may contain back-references to the pattern’s capture groups of the ' \
                            'form &bsol;d, where d is a group number, or &bsol;k&lt;n&gt;, ' \
                            'where n is a group ' \
                            'name. If it is a double-quoted string, both back-references must be ' \
                            'preceded by an additional backslash. However, within replacement the ' \
                            'special match variables, such as &#36;&amp;, will not refer to the ' \
                            'current match.',
                      optional: false
                    }
                  ]
                },
                {
                  name: 'use_operation_names_for_grouping',
                  label: 'Use HTTP method semantics for grouping operations',
                  hint: 'HTTP methods can indicate the desired action ' \
                        '(Get, Create, Update, Delete or Search) ' \
                        'to be performed for a given object. ' \
                        'Only disable this if the API endpoints don\'t follow the ' \
                        '<a target="_blank" href="https://restfulapi.net/">REST guidelines</a> for ' \
                        'HTTP methods to indicate actions. Defaults to Yes.',
                  optional: true,
                  control_type: 'checkbox',
                  type: 'boolean',
                  convert_input: 'boolean_conversion'
                },
                {
                  name: 'substitutions_for_grouping',
                  label: 'Substitutions for endpoint grouping',
                  hint: 'Add text substitutions to customize grouping of endpoint operations. ' \
                        'Only required in case built-in rules are not sufficient. ' \
                        '<a target="_blank" href="https://docs.workato.com/connectors/openapi/' \
                        'guides/customizing-openapi-interfaces.html#api-operation-grouping">' \
                        'Learn more</a> about endpoint grouping.',
                  optional: true,
                  type: 'array',
                  of: 'object',
                  list_mode: 'static',
                  item_label: 'Substitution rule',
                  add_item_label: 'Add substitution rule',
                  empty_list_text: 'Add text substitutions to customize endpoint grouping.',
                  properties: [
                    {
                      name: 'apply_to',
                      hint: 'If required, only apply this rule on the specified field. ' \
                            'Defaults to all: Summary, Operation ID, Description and Path',
                      control_type: 'select',
                      pick_list: [
                        %w[Summary summary],
                        %w[Operation\ ID operation_id],
                        %w[Description description],
                        %w[Path path]
                      ],
                      optional: true
                    },
                    {
                      name: 'pattern',
                      hint: 'Regular expression string, optionally including capture groups.',
                      optional: false
                    },
                    {
                      name: 'replacement',
                      hint: 'String replacing all occurrences of pattern. ' \
                            'It may contain back-references to the pattern’s capture groups of the ' \
                            'form &bsol;d, where d is a group number, or &bsol;k&lt;n&gt;, ' \
                            'where n is a group ' \
                            'name. If it is a double-quoted string, both back-references must be ' \
                            'preceded by an additional backslash. However, within replacement the ' \
                            'special match variables, such as &#36;&amp;, will not refer to the ' \
                            'current match.',
                      optional: false
                    }
                  ]
                },
                {
                  name: 'operation_id_substitution_for_grouping',
                  ngIf: 'input.advanced.operation_id_substitution_for_grouping != null',
                  label: 'Operation ID substitutions for endpoint grouping (deprecated)',
                  hint: 'Add substitutions to customize grouping of endpoint operations. ' \
                        'Only required in case built-in rules are not sufficient.',
                  optional: true,
                  type: 'array',
                  of: 'object',
                  list_mode: 'static',
                  item_label: 'Operation ID substitution',
                  add_item_label: 'Add substitution',
                  empty_list_text: 'Add operation ID substitutions to customize endpoint grouping.',
                  properties: [
                    {
                      name: 'pattern',
                      hint: 'Regular expression string, optionally including capture groups.',
                      optional: false
                    },
                    {
                      name: 'replacement',
                      hint: 'String replacing all occurrences of pattern. ' \
                            'It may contain back-references to the pattern’s capture groups of the ' \
                            'form &bsol;d, where d is a group number, or &bsol;k&lt;n&gt;, ' \
                            'where n is a group ' \
                            'name. If it is a double-quoted string, both back-references must be ' \
                            'preceded by an additional backslash. However, within replacement the ' \
                            'special match variables, such as &#36;&amp;, will not refer to the ' \
                            'current match.',
                      optional: false
                    }
                  ]
                },
                {
                  name: 'documentation_href',
                  label: 'Documentation link',
                  hint: 'Link to the application documentation, user guides, or company web site.',
                  optional: true
                },
                {
                  name: 'external_links',
                  control_type: 'key_value',
                  label: 'External documentation links',
                  hint: 'Add base URLs for tag names to allow field descriptions to link to external ' \
                        'websites like API references or other documentation. ' \
                        'Schema descriptions in OpenAPI often describe external links ' \
                        'like this: [&lt;Label&gt;](&lt;tag&gt;:&lt;path&gt;), ' \
                        'e.g. See [Permissions](doc:permissions)',
                  item_label: 'Documentation link',
                  add_item_label: 'Add documentation link',
                  empty_list_text: 'Add links to external documentation for tag names mentioned ' \
                                   'in the OpenAPI document.',
                  type: 'array',
                  of: 'object',
                  properties: [
                    {
                      name: 'key',
                      label: 'Tag name',
                      hint: 'E.g. doc, ref'
                    },
                    {
                      name: 'value',
                      label: 'Base URL',
                      hint: 'Base URL for external resources, e.g. http://example.com/api/reference/'
                    }
                  ]
                },
                {
                  name: 'ignore_request_fields',
                  label: 'Ignore specific request fields',
                  hint: 'List the names of fields to not show on the action\'s setup page.',
                  optional: true,
                  type: 'array',
                  of: 'object',
                  list_mode: 'static',
                  item_label: 'Field to ignore',
                  add_item_label: 'Add field to ignore',
                  empty_list_text: 'Add fields to ignore.',
                  properties: [
                    {
                      name: 'path',
                      label: 'Field name',
                      hint: 'Name of the field to ignore. In case of nested fields, ' \
                            'provide the path of field names, separated with a dot (.)',
                      optional: false
                    }
                  ]
                },
                {
                  name: 'endpoint_filter_rules',
                  label: 'Filter API endpoints',
                  hint: 'List of rules for filtering (including and/or excluding) API endpoints.',
                  optional: true,
                  type: 'array',
                  of: 'object',
                  list_mode: 'static',
                  item_label: 'Filter rule',
                  add_item_label: 'Add filter rule',
                  empty_list_text: 'No endpoint filter rules configured.',
                  properties: [
                    {
                      name: 'type',
                      optional: false,
                      control_type: 'select',
                      hint: 'Specify if this rule includes or excludes matching API endpoints. ' \
                            'All <b>Include</b> rules are applied first, ' \
                            'then all the <b>Exclude</b> rules are applied. ' \
                            'The below conditions are combined by the AND-operator.',
                      options: [
                        %w[Include include],
                        %w[Exclude exclude]
                      ]
                    },
                    {
                      name: 'http_method',
                      label: 'HTTP method',
                      optional: true,
                      control_type: 'multiselect',
                      delimiter: ',',
                      hint: 'Specify the HTTP methods to match. ' \
                            'If case multiple are selected, OR condition is applied. ' \
                            'Ignore this field if no need to filter by HTTP methods.',
                      options: [
                        %w[GET get],
                        %w[POST post],
                        %w[PUT put],
                        %w[PATCH patch],
                        %w[DELETE delete]
                      ]
                    },
                    {
                      name: 'tag',
                      label: 'Tag',
                      optional: true,
                      hint: '<a href="https://en.wikipedia.org/wiki/Regular_expression' \
                            '#POSIX_basic_and_extended" target="_blank">Regular expres' \
                            'sion</a> string to match endpoint <a href="https://swagge' \
                            'r.io/specification/#tag-object"' \
                            ' target="_blank">Tags</a>. ' \
                            'Ignore this field if no need to filter by tags.'
                    },
                    {
                      name: 'operation_id',
                      label: 'Operation ID',
                      optional: true,
                      hint: '<a href="https://en.wikipedia.org/wiki/Regular_expression' \
                            '#POSIX_basic_and_extended" target="_blank">Regular expres' \
                            'sion</a> string to match endpoint ' \
                            '<a href="https://swagger.io/specification/#operation-object" ' \
                            'target="_blank">Operation</a> IDs. ' \
                            'Ignore this field if no need to filter by operation IDs.'
                    },
                    {
                      name: 'path',
                      label: 'URL path',
                      optional: true,
                      hint: '<a href="https://en.wikipedia.org/wiki/Regular_expression' \
                            '#POSIX_basic_and_extended" target="_blank">Regular expres' \
                            'sion</a> string to match endpoint ' \
                            '<a href="https://swagger.io/specification/#paths-object" ' \
                            'target="_blank">Path</a> patterns. ' \
                            'Ignore this field if no need to filter by URL paths.'
                    }
                  ]
                },
                {
                  name: 'record_id_field_name',
                  label: 'Record ID field name',
                  hint: 'Name of the field holding values identifying individual object records.',
                  optional: true,
                  type: 'string'
                },
                {
                  name: 'allow_multi_paragraph_hint',
                  label: 'Allow long field hints',
                  hint: 'By default, hints will be stripped to a single paragraph.',
                  type: 'boolean',
                  control_type: 'checkbox',
                  optional: true
                },
                {
                  name: 'max_schema_depth',
                  label: 'Schema depth limit',
                  hint: 'Maximum depth for nested fields to be included in ' \
                        'input and output schema descriptions. ',
                  type: 'integer',
                  control_type: 'integer',
                  convert_input: 'integer_conversion',
                  optional: true
                },
                {
                  name: 'max_recursion_depth',
                  label: 'Schema recursion limit',
                  hint: 'Maximum depth recursive schema definitions to be included in ' \
                        'input and output schema descriptions. ',
                  type: 'integer',
                  control_type: 'integer',
                  convert_input: 'integer_conversion',
                  optional: true
                }
              ]
            }
          ],

          apply: lambda do |connection|
            auth_input_headers_string = connection['auth_headers']
            auth_headers_key_value = connection['auth_headers_key_value']
            if auth_input_headers_string.present?
              lines = auth_input_headers_string&.split(/\n+|\r+/)
              headers_hash = {}
              lines&.each do |header|
                next if header.blank?

                header = header.split(':', 2)
                next if header.length != 2

                header_name = header[0]
                header_value = header[1].strip
                headers_hash[header_name] = header_value
              end
              case_sensitive_headers(headers_hash) if headers_hash.present?
            elsif auth_headers_key_value.present?
              key_value_hash = auth_headers_key_value.each_with_object({}) do |item, hash|
                key = item['key']
                value = item['value']
                hash[key] = value unless key.blank?
              end
              case_sensitive_headers(key_value_hash) if key_value_hash.present?
            end
          end
        },

      }
    },

    base_uri: lambda do |connection|
      base_url = connection['base_url']
      # does not end with slash?
      unless base_url.blank? || base_url.ends_with?('/')
        # append / to the base URL
        base_url = "#{base_url}/"
      end
      base_url
    end
  },

  test: lambda do |connection|
    connection = call('adjust_connection', connection, {})
    api_definition = call('get_api_definition', connection)
    if api_definition.present?
      openapi_version = call('get_openapi_version', api_definition)
      call('get_openapi_version_method_prefix', openapi_version)
    end
    path = connection.dig('advanced', 'test_endpoint')
    path = connection['test_endpoint'] if path.nil?
    unless path.blank?
      path = path[1..-1] if path.starts_with?('/')
      get(path)
    end
  end,

  object_definitions: {

    get_record_input: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_input_fields', connection, input, 'get')
      end
    },

    get_record_output: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_output_fields', connection, input, 'get')
      end
    },

    create_record_input: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_input_fields', connection, input, 'create')
      end
    },

    create_record_output: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_output_fields', connection, input, 'create')
      end
    },

    update_record_input: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_input_fields', connection, input, 'update')
      end
    },

    update_record_output: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_output_fields', connection, input, 'update')
      end
    },

    delete_record_input: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_input_fields', connection, input, 'delete')
      end
    },

    delete_record_output: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_output_fields', connection, input, 'delete')
      end
    },

    search_records_input: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_input_fields', connection, input, 'search')
      end
    },

    search_records_output: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_output_fields', connection, input, 'search')
      end
    },

    execute_operation_input: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_input_fields', connection, input, 'execute')
      end
    },

    execute_operation_output: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('get_action_output_fields', connection, input, 'execute')
      end
    },

    custom_action_input: {
      fields: lambda do |connection, config_fields|
        connection = call('adjust_connection', connection, config_fields)
        verb = config_fields['verb']
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')
        data_props =
          input_schema.map do |field|
            if config_fields['request_type'] == 'multipart' &&
               field['binary_content'] == 'true'
              field['type'] = 'object'
              field['properties'] = [
                { name: 'file_content', optional: false },
                {
                  name: 'content_type',
                  default: 'text/plain',
                  sticky: true
                },
                { name: 'original_filename', sticky: true }
              ]
            end
            field
          end
        data_props = call('make_schema_builder_fields_sticky', data_props)
        input_data =
          if input_schema.present?
            if input_schema.dig(0, 'type') == 'array' &&
               input_schema.dig(0, 'details', 'fake_array')
              {
                name: 'data',
                type: 'array',
                of: 'object',
                properties: data_props.dig(0, 'properties')
              }
            else
              { name: 'data', type: 'object', properties: data_props }
            end
          end

        [
          {
            name: 'path',
            hint: 'Base URI is <b>' \
                  "#{connection['base_url']}" \
                  '</b> - path will be appended to this URI. Use absolute URI to ' \
                  'override this base URI.',
            optional: false
          },
          if %w[post put patch].include?(verb)
            {
              name: 'request_type',
              default: 'json',
              sticky: true,
              extends_schema: true,
              control_type: 'select',
              pick_list: [
                ['JSON request body', 'json'],
                ['URL encoded form', 'url_encoded_form'],
                ['Mutipart form', 'multipart'],
                ['Raw request body', 'raw']
              ]
            }
          end,
          {
            name: 'response_type',
            default: 'json',
            sticky: false,
            extends_schema: true,
            control_type: 'select',
            pick_list: [['JSON response', 'json'], ['Raw response', 'raw']]
          },
          if %w[get options delete].include?(verb)
            {
              name: 'input',
              label: 'Request URL parameters',
              sticky: true,
              add_field_label: 'Add URL parameter',
              control_type: 'form-schema-builder',
              type: 'object',
              properties: [
                {
                  name: 'schema',
                  sticky: input_schema.blank?,
                  extends_schema: true
                },
                input_data
              ].compact
            }
          else
            {
              name: 'input',
              label: 'Request body parameters',
              sticky: true,
              type: 'object',
              properties:
                if config_fields['request_type'] == 'raw'
                  [{
                    name: 'data',
                    sticky: true,
                    control_type: 'text-area',
                    type: 'string'
                  }]
                else
                  [
                    {
                      name: 'schema',
                      sticky: input_schema.blank?,
                      extends_schema: true,
                      schema_neutral: true,
                      control_type: 'schema-designer',
                      sample_data_type: 'json_input',
                      custom_properties:
                        if config_fields['request_type'] == 'multipart'
                          [{
                            name: 'binary_content',
                            label: 'File attachment',
                            default: false,
                            optional: true,
                            sticky: true,
                            render_input: 'boolean_conversion',
                            parse_output: 'boolean_conversion',
                            control_type: 'checkbox',
                            type: 'boolean'
                          }]
                        end
                    },
                    input_data
                  ].compact
                end
            }
          end,
          {
            name: 'request_headers',
            sticky: false,
            extends_schema: true,
            control_type: 'key_value',
            empty_list_title: 'Does this HTTP request require headers?',
            empty_list_text: 'Refer to the API documentation and add ' \
                             'required headers to this HTTP request',
            item_label: 'Header',
            type: 'array',
            of: 'object',
            properties: [{ name: 'key' }, { name: 'value' }]
          },
          unless config_fields['response_type'] == 'raw'
            {
              name: 'output',
              label: 'Response body',
              sticky: true,
              extends_schema: true,
              schema_neutral: true,
              control_type: 'schema-designer',
              sample_data_type: 'json_input'
            }
          end,
          {
            name: 'response_headers',
            sticky: false,
            extends_schema: true,
            schema_neutral: true,
            control_type: 'schema-designer',
            sample_data_type: 'json_input'
          }
        ].compact
      end
    },

    custom_action_output: {
      fields: lambda do |_connection, config_fields|
        response_body = { name: 'body' }

        [
          if config_fields['response_type'] == 'raw'
            response_body
          elsif (output = config_fields['output'])
            output_schema = call('format_schema', parse_json(output))
            if output_schema.dig(0, 'type') == 'array' &&
               output_schema.dig(0, 'details', 'fake_array')
              response_body[:type] = 'array'
              response_body[:properties] = output_schema.dig(0, 'properties')
            else
              response_body[:type] = 'object'
              response_body[:properties] = output_schema
            end

            response_body
          end,
          if (headers = config_fields['response_headers'])
            header_props = parse_json(headers)&.map do |field|
              if field[:name].present?
                field[:name] = field[:name].gsub(/\W/, '_').downcase
              elsif field['name'].present?
                field['name'] = field['name'].gsub(/\W/, '_').downcase
              end
              field
            end

            { name: 'headers', type: 'object', properties: header_props }
          end
        ].compact
      end
    },

    new_or_updated_record_input: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        fields = []

        # object picklist
        endpoint = call('get_endpoint', connection, input, 'new_or_updated_trigger')
        endpoint_hint = 'Select any object.'
        endpoint_hint = call('get_endpoint_hints', connection, endpoint) unless endpoint.nil?
        fields.push(
          {
            name: 'object_for_new_or_updated_trigger',
            label: 'Object',
            hint: endpoint_hint,
            control_type: 'select',
            pick_list: 'object_for_new_or_updated_trigger',
            extends_schema: true,
            schema_neutral: false,
            optional: false,
            sticky: true
          }.compact
        )

        # add since timestamp field
        fields << {
          name: 'since',
          label: 'When first started, this recipe should pick up events from',
          hint: 'When you start recipe for the first time, it picks up ' \
            'trigger events from this specified date and time. Leave ' \
            'empty to get events created one hour ago.',
          sticky: true,
          optional: true,
          type: 'date_time'
        }

        # get endpoint fields
        if endpoint.present?
          request_fields = call(
            'request_fields',
            connection,
            endpoint
          )
          response_fields = call(
            'response_fields',
            connection,
            'search',
            endpoint
          )
        end

        # filtering group
        # NOTE: when adding non-app-specific/config fields to this list,
        #       make sure to exclude them
        #       from the when sending the HTTP request.
        filter_fields = []
        fields << {
          name: 'filter',
          label: 'Filter',
          hint: 'Provide configuration and filter criteria ' \
                'for checking for new or updated records.',
          type: 'object',
          properties: filter_fields
        }
        filter_input = input['filter'] || {}

        # filter field picker
        unless request_fields.nil?
          possible_timestamp_fields = call(
            'get_timestamp_request_fields',
            connection,
            request_fields
          )
          timestamp_field_pick_list = possible_timestamp_fields&.map do |field|
            name = field[:name]
            label = field[:label]
            label = call('labelize', name) if label.blank?
            [label, name]
          end
          if timestamp_field_pick_list&.length == 1
            request_field_default_label = timestamp_field_pick_list.first[0]
            timestamp_request_field_hint_suffix = ' Defaults to ' \
                                                  "#{request_field_default_label}."
          end
          filter_fields.push(
            {
              name: '__timestamp_field',
              label: 'Timestamp field',
              hint: 'When asking for new records, this field will be used to filter ' \
                    'for only newly created or updated records.' \
                    "#{timestamp_request_field_hint_suffix}",
              control_type: 'select',
              pick_list: timestamp_field_pick_list,
              extends_schema: true,
              schema_neutral: false,
              optional: request_field_default_label.present?
            }.compact
          )
          filter_timestamp_field_name = filter_input['__timestamp_field']
          if filter_timestamp_field_name.blank?
            if possible_timestamp_fields&.length == 1
              timestamp_field = possible_timestamp_fields.first
            end
          else
            timestamp_field = possible_timestamp_fields&.find do |field|
              field[:name] == filter_timestamp_field_name
            end
          end
        end

        # filter timestamp format
        if timestamp_field.present? && timestamp_field[:type] == 'string'
          request_format_hint = 'By default, timestamps will be formatted according ' \
                                'ISO standard. ' \
                                'If this isn\'t applicable, provide a custom timestamp format. ' \
                                '<a href="https://apidock.com/ruby/DateTime/strftime" ' \
                                'target="_blank">' \
                                'Formatting Directives</a>'
          unless timestamp_field[:hint].blank?
            request_format_hint = "#{request_format_hint} <br><br>" \
                                  "#{timestamp_field[:label]}: " \
                                  "#{timestamp_field[:hint]}"
          end
          filter_fields.push(
            {
              name: '__timestamp_format',
              hint: request_format_hint,
              label: 'Timestamp format',
              optional: true,
              schema_neutral: false
            }.compact
          )
        end

        # record list field picker
        if response_fields.present?
          response_list_fields = call(
            'get_search_operation_response_list_fields',
            connection,
            response_fields
          )
          list_field_pick_list = response_list_fields.map do |field|
            name = field[:name]
            label = field[:label]
            label = call('labelize', name) if label.blank?
            [label, name]
          end
        end
        if list_field_pick_list.present?
          if list_field_pick_list.length == 1
            response_list_field_default_label = list_field_pick_list.first[0]
            response_list_field_hint_suffix = ' Defaults to ' \
                                              "#{response_list_field_default_label}."
          end
          fields << {
            name: 'record_list_field',
            label: 'Record list field',
            hint: 'Records in this field will be available as output of this trigger.' \
                  "#{response_list_field_hint_suffix}",
            control_type: 'select',
            pick_list: list_field_pick_list,
            extends_schema: true,
            schema_neutral: false,
            optional: response_list_field_default_label.present?
          }.compact
          response_list_field_name = input['record_list_field']
          if response_list_field_name.blank?
            response_list_field = response_list_fields.first if list_field_pick_list.length == 1
          else
            response_list_field = response_list_fields.find do |field|
              field[:name] == response_list_field_name
            end
          end
        end

        # record identifier field picker
        if response_list_field&.present?
          possible_identifier_fields = call(
            'get_record_identifier_fields',
            connection,
            response_list_field[:properties]
          )
          identifier_field_pick_list = possible_identifier_fields&.map do |field|
            name = field[:name]
            label = field[:label]
            label = call('labelize', name) if label.blank?
            [label, name]
          end
          if identifier_field_pick_list&.length == 1
            default_record_identifier_field_label = identifier_field_pick_list.first[0]
            record_identifier_field_hint_suffix = ' Defaults to ' \
                                                  "#{default_record_identifier_field_label}."
          end
          fields.push(
            {
              name: 'record_identifier_field',
              label: 'Identifier record field',
              hint: 'Field that uniquely identifies individual records. ' \
                    'This is required to carry out deduplication to ensure ' \
                    'each unique record is processed only once.' \
                    "#{record_identifier_field_hint_suffix}",
              type: 'string',
              control_type: 'select',
              pick_list: identifier_field_pick_list,
              optional: default_record_identifier_field_label.present?
            }.compact
          )
        end

        # Changed/updated timestamp field of records
        unless response_list_field.nil?
          record_timestamp_fields = call(
            'get_record_timestamp_fields',
            connection,
            response_list_field[:properties]
          )
          record_timestamp_field_pick_list = record_timestamp_fields&.map do |field|
            name = field[:name]
            label = field[:label]
            label = call('labelize', name) if label.blank?
            [label, name]
          end
          if record_timestamp_field_pick_list&.length == 1
            record_timestamp_field_default_label = record_timestamp_field_pick_list.first[0]
            timestamp_request_field_hint_suffix = ' Defaults to ' \
                                                  "#{record_timestamp_field_default_label}."
          end

          fields << {
            name: 'record_timestamp_field',
            label: 'Timestamp record field',
            hint: 'Used to determine the latest timestamp for filtering ' \
                  'when asking for new events next.' \
                  "#{timestamp_request_field_hint_suffix}",
            control_type: 'select',
            pick_list: record_timestamp_field_pick_list,
            extends_schema: true,
            schema_neutral: false,
            optional: record_timestamp_field_default_label.present?
          }.compact
          record_timestamp_field_name = input['record_timestamp_field']
          if record_timestamp_field_name.blank?
            if record_timestamp_fields&.length == 1
              record_timestamp_field = record_timestamp_fields.first
            end
          else
            record_timestamp_field = record_timestamp_fields&.find do |field|
              field[:name] == record_timestamp_field_name
            end
          end
        end

        # Changed/updated timestamp format
        if record_timestamp_field.present? && record_timestamp_field[:type] == 'string'
          record_timestamp_field_hint = 'By default, record timestamps will be parsed ' \
                                        'according ISO standard. ' \
                                        'If this isn\'t applicable, provide a custom timestamp ' \
                                        'format. ' \
                                        '<a href="https://apidock.com/ruby/DateTime/strpt' \
                                        'ime/class" target="_blank">' \
                                        'Parsing Directives</a>'
          unless record_timestamp_field[:hint].blank?
            record_timestamp_field_hint = "#{record_timestamp_field_hint} <br><br>" \
                                          "#{record_timestamp_field[:hint]}"
          end
          fields << {
            name: 'record_timestamp_format',
            hint: record_timestamp_field_hint,
            label: 'Expected timestamp format',
            optional: true
          }.compact
        end

        # Add pagination
        pagination_mode_pick_list = []
        pagination_fields_generator = []

        # Add cursor pagination
        cursor_request_fields = call(
          'get_cursor_pagination_request_fields',
          connection,
          request_fields
        )
        cursor_response_fields = call(
          'get_cursor_pagination_response_fields',
          connection,
          response_fields
        )
        if cursor_request_fields.present? && cursor_response_fields.present?
          pagination_mode_pick_list.push(
            %w[Cursor cursor]
          )
          cursor_request_field_pick_list = cursor_request_fields&.map do |field|
            name = field[:name]
            label = field[:label]
            label = call('labelize', name) if label.blank?
            [label, name]
          end
          if cursor_request_field_pick_list.length == 1
            cursor_request_field_default_label = cursor_request_field_pick_list.first[0]
            cursor_request_field_hint_suffix = ' Defaults to ' \
                                               "#{cursor_request_field_default_label}."
          end
          cursor_response_field_pick_list = cursor_response_fields&.map do |field|
            name = field[:name]
            label = field[:label]
            label = call('labelize', name) if label.blank?
            [label, name]
          end
          if cursor_response_field_pick_list.length == 1
            cursor_response_field_default_label = cursor_response_field_pick_list.first[0]
            cursor_response_field_hint_suffix = ' Defaults to ' \
                                                "#{cursor_response_field_default_label}."
          end
          pagination_fields_generator.push(lambda do |_input|
            [
              {
                name: 'cursor_request_field',
                label: 'Cursor request field',
                hint: 'Select the request cursor field.' \
                      "#{cursor_request_field_hint_suffix}",
                type: 'string',
                control_type: 'select',
                pick_list: cursor_request_field_pick_list,
                optional: cursor_request_field_default_label.present?,
                extends_schema: true,
                schema_neutral: false
              },
              {
                name: 'cursor_response_field',
                label: 'Cursor response field',
                hint: 'Response field will contain the cursor used to retrieve the next page.' \
                      "#{cursor_response_field_hint_suffix}",
                type: 'string',
                control_type: 'select',
                pick_list: cursor_response_field_pick_list,
                optional: cursor_response_field_default_label.present?,
                extends_schema: true,
                schema_neutral: false
              }
            ]
          end)
        end

        # Add next-link pagination
        next_link_response_fields = call(
          'get_next_link_pagination_response_fields',
          connection,
          response_fields
        )
        next_link_field_pick_list = next_link_response_fields&.map do |field|
          name = field[:name]
          label = field[:label]
          label = call('labelize', name) if label.blank?
          [label, name]
        end
        if next_link_field_pick_list.present?
          pagination_mode_pick_list.push(
            %w[Next\ page\ link next_link]
          )
          if next_link_field_pick_list.length == 1
            next_link_field_default_label = next_link_field_pick_list.first[0]
            next_link_field_hint_suffix = ' Defaults to ' \
                                          "#{next_link_field_default_label}."
          end
          pagination_fields_generator.push(lambda do |_input|
            [
              {
                name: 'next_link_field',
                label: 'Next page link field',
                hint: 'Response field will contain the link to retrieve the next page.' \
                      "#{next_link_field_hint_suffix}",
                type: 'string',
                control_type: 'select',
                pick_list: next_link_field_pick_list,
                optional: next_link_field_default_label.present?,
                extends_schema: true,
                schema_neutral: false
              }
            ]
          end)
        end

        # Add pagination fields
        if pagination_mode_pick_list.length > 0
          if pagination_mode_pick_list.length == 1
            default_pagination_mode_label = pagination_mode_pick_list.first[0]
            pagination_mode_hint_suffix = ' Defaults to ' \
                                          "#{default_pagination_mode_label}."
          end
          pagination_mode_field = {
            name: 'mode',
            label: 'Mode',
            hint: 'Select how pagination should handled.' \
                  "#{pagination_mode_hint_suffix}",
            control_type: 'select',
            pick_list: pagination_mode_pick_list,
            optional: default_pagination_mode_label.present?,
            extends_schema: true,
            schema_neutral: false
          }
          pagination_mode = input.dig('pagination', 'mode')
          pagination_mode = pagination_mode_pick_list.first[1] if pagination_mode.blank?
          pagination_mode_index = pagination_mode_pick_list.find_index do |item|
            item[1] == pagination_mode
          end
          unless pagination_mode_index.nil?
            fields_generator = pagination_fields_generator[pagination_mode_index]
          end
          if fields_generator.nil?
            fields_generator = lambda do |_|
              []
            end
          end
          pagination_fields = [pagination_mode_field] + fields_generator.call(input['pagination'])
        end
        if pagination_fields.present?
          fields.push(
            {
              name: 'pagination',
              label: 'Pagination',
              hint: 'For large number of records, ' \
                    'pagination will be used to retrieve the records in pages.',
              type: 'object',
              properties: pagination_fields
            }.compact
          )
        end

        # additional filter fields
        request_fields&.select do |field|
          filter_timestamp_field_name = timestamp_field&.dig(:name)
          next if field[:name] == filter_timestamp_field_name

          case pagination_mode
          when 'cursor'
            # TODO: also consider default value for 'cursor_request_field'
            next if field[:name] == input.dig('pagination', 'cursor_request_field')
          end

          # make fields non-sticky
          field[:sticky] = false
          filter_fields << field
        end

        # remove empty groups
        fields.delete_if do |field|
          field[:type] == 'object' && field[:properties].empty?
        end

        call('format_schema', fields)
      end
    },

    new_or_updated_record_output: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        fields = []
        endpoint = call('get_endpoint', connection, input, 'new_or_updated_trigger')
        if endpoint.present?
          endpoint_fields = call(
            'response_fields',
            connection,
            'search',
            endpoint
          )
          response_list_fields = call(
            'get_search_operation_response_list_fields',
            connection,
            endpoint_fields
          )
        end
        response_list_field_name = input['record_list_field']
        if response_list_field_name.present?
          response_list_field = response_list_fields&.find do |field|
            field[:name] == response_list_field_name
          end
        elsif response_list_fields.present? && response_list_fields.length == 1
          response_list_field = response_list_fields.first
        end
        fields.concat response_list_field[:properties] if response_list_field.present?
        call('format_schema', fields)
      end
    },

    new_or_updated_record_output_batch: {
      fields: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        fields = []
        endpoint = call('get_endpoint', connection, input, 'new_or_updated_trigger')
        if endpoint.present?
          endpoint_fields = call(
            'response_fields',
            connection,
            'search',
            endpoint
          )
          response_list_fields = call(
            'get_search_operation_response_list_fields',
            connection,
            endpoint_fields
          )
        end
        response_list_field_name = input['record_list_field']
        if response_list_field_name.present?
          response_list_field = response_list_fields&.find do |field|
            field[:name] == response_list_field_name
          end
        elsif response_list_fields.present? && response_list_fields.length == 1
          response_list_field = response_list_fields.first
        end
        fields.concat response_list_field[:properties] if response_list_field.present?
        if input['object_for_new_or_updated_trigger'].present?
          [
            name: 'list', type: 'array', of: 'object',
            properties: call('format_schema', fields)
          ]
        else
          []
        end
      end
    }
  },

  actions: {

    get_record: {
      title: 'Get record details by ID',
      subtitle: 'Retrieve the details of a record by ID via OpenAPI',
      help: lambda do |_input, _picklist_label|
        {
          body: 'Retrieve the details of a record by ID via OpenAPI. ' \
                'The list of objects is dynamically generated based on the API endpoints ' \
                'found in the OpenAPI document. ' \
                'If an API endpoint can\'t be matched to any of the Create, Get, Search, Update ' \
                'or Delete actions, it will be grouped under the Execute operation action.',
          learn_more_url: 'https://docs.workato.com/connectors/openapi/guides/customizing-openapi-interfaces.html#api-operation-grouping',
          learn_more_text: 'Learn more about API endpoint grouping'
        }
      end,
      description: lambda do |_input, picklist_label|
        record = picklist_label['object_for_get'] || 'record'
        "Get <span class='provider'>#{record}</span> details " \
          'by ID via <span class="provider">OpenAPI</span>'
      end,
      config_fields: [],
      input_fields: lambda do |object_definitions|
        object_definitions['get_record_input']
      end,
      execute: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('execute_action', connection, input, 'get', overwrite_path: nil)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['get_record_output']
      end,
      sample_output: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('sample_action_output', connection, input, 'get')
      end
    },

    create_record: {
      title: 'Create record',
      subtitle: 'Create record via OpenAPI',
      help: lambda do |_input, _picklist_label|
        {
          body: 'Create a record via OpenAPI. ' \
                'The list of objects is dynamically generated based on the API endpoints ' \
                'found in the OpenAPI document. ' \
                'If an API endpoint can\'t be matched to any of the Create, Get, Search, Update ' \
                'or Delete actions, it will be grouped under the Execute operation action.',
          learn_more_url: 'https://docs.workato.com/connectors/openapi/guides/customizing-openapi-interfaces.html#api-operation-grouping',
          learn_more_text: 'Learn more about API endpoint grouping'
        }
      end,
      description: lambda do |_input, picklist_label|
        record = picklist_label['object_for_create'] || 'record'
        "Create <span class='provider'>#{record}</span> " \
          'via <span class="provider">OpenAPI</span>'
      end,
      config_fields: [],
      input_fields: lambda do |object_definitions|
        object_definitions['create_record_input']
      end,
      execute: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('execute_action', connection, input, 'create', overwrite_path: nil)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['create_record_output']
      end,
      sample_output: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('sample_action_output', connection, input, 'create')
      end
    },

    update_record: {
      title: 'Update record',
      subtitle: 'Update record via OpenAPI',
      help: lambda do |_input, _picklist_label|
        {
          body: 'Update a record via OpenAPI. ' \
                'The list of objects is dynamically generated based on the API endpoints ' \
                'found in the OpenAPI document. ' \
                'If an API endpoint can\'t be matched to any of the Create, Get, Search, Update ' \
                'or Delete actions, it will be grouped under the Execute operation action.',
          learn_more_url: 'https://docs.workato.com/connectors/openapi/guides/customizing-openapi-interfaces.html#api-operation-grouping',
          learn_more_text: 'Learn more about API endpoint grouping'
        }
      end,
      description: lambda do |_input, picklist_label|
        record = picklist_label['object_for_update'] || 'record'
        "Update <span class='provider'>#{record}</span> " \
          'via <span class="provider">OpenAPI</span>'
      end,
      config_fields: [],
      input_fields: lambda do |object_definitions|
        object_definitions['update_record_input']
      end,
      execute: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('execute_action', connection, input, 'update', overwrite_path: nil)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['update_record_output']
      end,
      sample_output: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('sample_action_output', connection, input, 'update')
      end
    },

    delete_record: {
      title: 'Delete record',
      subtitle: 'Delete record via OpenAPI',
      help: lambda do |_input, _picklist_label|
        {
          body: 'Delete a record via OpenAPI. ' \
                'The list of objects is dynamically generated based on the API endpoints ' \
                'found in the OpenAPI document. ' \
                'If an API endpoint can\'t be matched to any of the Create, Get, Search, Update ' \
                'or Delete actions, it will be grouped under the Execute operation action.',
          learn_more_url: 'https://docs.workato.com/connectors/openapi/guides/customizing-openapi-interfaces.html#api-operation-grouping',
          learn_more_text: 'Learn more about API endpoint grouping'
        }
      end,
      description: lambda do |_input, picklist_label|
        record = picklist_label['object_for_delete'] || 'record'
        "Delete <span class='provider'>#{record}</span> via <span class='provider'>OpenAPI</span>"
      end,
      config_fields: [],
      input_fields: lambda do |object_definitions|
        object_definitions['delete_record_input']
      end,
      execute: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('execute_action', connection, input, 'delete', overwrite_path: nil)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['delete_record_output']
      end,
      sample_output: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('sample_action_output', connection, input, 'delete')
      end
    },

    search_records: {
      title: 'Search records',
      subtitle: 'Search records via OpenAPI',
      help: lambda do |_input, _picklist_label|
        {
          body: 'Search records via OpenAPI. ' \
                'The list of objects is dynamically generated based on the API endpoints ' \
                'found in the OpenAPI document. ' \
                'If an API endpoint can\'t be matched to any of the Create, Get, Search, Update ' \
                'or Delete actions, it will be grouped under the Execute operation action.',
          learn_more_url: 'https://docs.workato.com/connectors/openapi/guides/customizing-openapi-interfaces.html#api-operation-grouping',
          learn_more_text: 'Learn more about API endpoint grouping'
        }
      end,
      description: lambda do |_input, picklist_label|
        record = picklist_label['object_for_search'] || 'records'
        "Search <span class='provider'>#{record}</span> via <span class='provider'>OpenAPI</span>"
      end,
      config_fields: [],
      input_fields: lambda do |object_definitions|
        object_definitions['search_records_input']
      end,
      execute: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('execute_action', connection, input, 'search', overwrite_path: nil)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['search_records_output']
      end,
      sample_output: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('sample_action_output', connection, input, 'search')
      end
    },

    execute_operation: {
      title: 'Execute operation',
      subtitle: 'Execute operation via OpenAPI',
      help: lambda do |_input, _picklist_label|
        {
          body: 'Execute a operation via OpenAPI. ' \
                'The list of operation is dynamically generated based on the API endpoints ' \
                'found in the OpenAPI document. ' \
                'Only if an API endpoint can\'t be matched to any of the Create, Get, Search ' \
                ', Update or Delete actions, it will be shown in this Execute operation action.',
          learn_more_url: 'https://docs.workato.com/connectors/openapi/guides/customizing-openapi-interfaces.html#api-operation-grouping',
          learn_more_text: 'Learn more about API endpoint grouping'
        }
      end,
      description: lambda do |input, picklist_label|
        label = input['operation_label']
        label = picklist_label['object_for_execute'] if label.blank?
        label = "<span class='provider'>#{label}</span>" unless label.blank?
        label = "Execute <span class='provider'>operation</span>" if label.blank?
        "#{label} via <span class='provider'>OpenAPI</span>"
      end,
      config_fields: [],
      input_fields: lambda do |object_definitions|
        object_definitions['execute_operation_input']
      end,
      execute: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('execute_action', connection, input, 'execute', overwrite_path: nil)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['execute_operation_output']
      end,
      sample_output: lambda do |connection, input|
        connection = call('adjust_connection', connection, input)
        call('sample_action_output', connection, input, 'execute')
      end
    },

    custom_action: {
      subtitle: 'Build your own OpenAPI action with a HTTP request',

      description: lambda do |object_value, _object_label|
        "<span class='provider'>" \
          "#{object_value[:action_name] || 'Custom action'}</span> via " \
          "<span class='provider'>OpenAPI</span>"
      end,

      help: {
        body: 'Build your own OpenAPI action with a HTTP request. ' \
              'The request will be authorized with your OpenAPI connection.'
      },

      config_fields: [
        {
          name: 'action_name',
          hint: "Give this action you're building a descriptive name, e.g. " \
                'create record, get record',
          default: 'Custom action',
          optional: false,
          schema_neutral: true
        },
        {
          name: 'verb',
          label: 'Method',
          hint: 'Select HTTP method of the request',
          optional: false,
          control_type: 'select',
          pick_list: %w[get post put delete patch].
            map { |verb| [verb.upcase, verb] }
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['custom_action_input']
      end,

      execute: lambda do |_connection, input|
        verb = input['verb']
        if %w[get post put patch options delete].exclude?(verb)
          error("#{verb.upcase} not supported")
        end
        path = input['path']
        data = input.dig('input', 'data') || {}
        if input['request_type'] == 'multipart'
          data = data.each_with_object({}) do |(key, val), hash|
            hash[key] = if val.is_a?(Hash)
                          [val[:file_content],
                           val[:content_type],
                           val[:original_filename]]
                        else
                          val
                        end
          end
        end
        request_headers = input['request_headers']&.each_with_object({}) do |item, hash|
          hash[item['key']] = item['value']
        end || {}
        request = case verb
                  when 'get'
                    get(path, data)
                  when 'post'
                    if input['request_type'] == 'raw'
                      post(path).request_body(data)
                    else
                      post(path, data)
                    end
                  when 'put'
                    if input['request_type'] == 'raw'
                      put(path).request_body(data)
                    else
                      put(path, data)
                    end
                  when 'patch'
                    if input['request_type'] == 'raw'
                      patch(path).request_body(data)
                    else
                      patch(path, data)
                    end
                  when 'options'
                    options(path, data)
                  when 'delete'
                    delete(path, data)
                  end.case_sensitive_headers(request_headers)
        request = case input['request_type']
                  when 'url_encoded_form'
                    request.request_format_www_form_urlencoded
                  when 'multipart'
                    request.request_format_multipart_form
                  else
                    request
                  end
        response =
          if input['response_type'] == 'raw'
            request.response_format_raw
          else
            request
          end.
          after_error_response(/.*/) do |code, body, headers, message|
            error({ code: code, message: message, body: body, headers: headers }.
              to_json)
          end

        response.after_response do |_code, res_body, res_headers|
          {
            body: res_body ? call('format_response', res_body) : nil,
            headers: res_headers
          }
        end
      end,

      output_fields: lambda do |object_definition|
        object_definition['custom_action_output']
      end
    }
  },

  triggers: {
    new_or_updated_record: {
      title: 'New/updated record',
      help: lambda do |_input, _picklist_label|
        {
          body: 'Triggers when a record of the selected object is created/updated. ' \
                'The list of objects is dynamically generated based on the API endpoints ' \
                'found in the OpenAPI document. ' \
                '<br><br>' \
                'After selecting the object from the picklist, all the required ' \
                'information for handling time-ranges and pagination will be ' \
                'auto-detected from OpenAPI schema definition. ' \
                'In some cases, you may need to manually provide additional information.'
        }
      end,
      subtitle: 'Triggers when selected object is created/updated',
      description: lambda do |_input, picklist_label|
        object = picklist_label['object_for_new_or_updated_trigger'] || 'record'
        "New/updated <span class='provider'>#{object}" \
          "</span> via <span class='provider'>OpenAPI</span>"
      end,
      input_fields: lambda do |object_definitions|
        object_definitions['new_or_updated_record_input']
      end,
      poll: lambda do |connection, input, closure|
        input = call('format_payload', input)
        connection = call('adjust_connection', connection, input)
        endpoint = call('get_endpoint', connection, input, 'new_or_updated_trigger')
        request_fields = call(
          'request_fields',
          connection,
          endpoint
        )
        response_fields = call(
          'response_fields',
          connection,
          'search',
          endpoint
        )

        filter_input = input['filter'] || {}

        # prepare the 'search' action input
        endpoint_input = {
          'object_for_search' => endpoint.to_json
        }
        # NOTE: when adding new config-fields make sure they are excluded here
        app_filter_values = filter_input.except(
          '__timestamp_field',
          '__timestamp_format'
        )
        endpoint_input = endpoint_input.merge(app_filter_values) if app_filter_values.present?

        # Get pagination mode
        pagination_input = input['pagination'] || {}
        pagination_mode = pagination_input['mode']
        possible_pagination_modes = []
        cursor_request_fields = call(
          'get_cursor_pagination_request_fields',
          connection,
          request_fields
        )
        cursor_response_fields = call(
          'get_cursor_pagination_response_fields',
          connection,
          response_fields
        )
        if cursor_request_fields.present? && cursor_response_fields.present?
          possible_pagination_modes << 'cursor'
        end
        next_link_response_fields = call(
          'get_next_link_pagination_response_fields',
          connection,
          response_fields
        )
        possible_pagination_modes << 'next_link' if next_link_response_fields.present?
        if possible_pagination_modes.length == 1
          pagination_mode_default = possible_pagination_modes.first
        end
        if pagination_mode.blank? && pagination_mode_default.present?
          pagination_mode = pagination_mode_default
        end

        # Handle cursor pagination
        cursor_request_field_name = pagination_input['cursor_request_field']
        cursor_response_field_name = pagination_input['cursor_response_field']
        if pagination_mode == 'cursor'
          if cursor_request_field_name.blank? && cursor_request_fields&.length == 1
            cursor_request_field_name = cursor_request_fields&.first&.[](:name)
          end
          error('Cursor pagination requires request field') if cursor_request_field_name.blank?
          if cursor_response_field_name.blank? && cursor_response_fields&.length == 1
            cursor_response_field_name = cursor_response_fields&.first&.[](:name)
          end
          error('Cursor pagination requires response field') if cursor_response_field_name.blank?
          if closure&.has_key?('cursor')
            endpoint_input[cursor_request_field_name] = closure['cursor']
          end
        end

        # Handle next-link pagination
        cursor_next_link_field_name = pagination_input['next_link_field']
        if pagination_mode == 'next_link'
          if cursor_next_link_field_name.blank? && next_link_response_fields&.length == 1
            cursor_next_link_field_name = next_link_response_fields&.first&.[](:name)
          end
          if cursor_next_link_field_name.blank?
            error('Next-link pagination requires response field')
          end
          overwrite_path = closure['next_link'] if closure&.[]('next_link').present?
        end

        # Get return timestamp field
        request_timestamp_field_name = filter_input['__timestamp_field']
        if request_timestamp_field_name.blank?
          possible_timestamp_fields = call(
            'get_timestamp_request_fields',
            connection,
            request_fields
          )
          if possible_timestamp_fields&.length == 1
            request_timestamp_field_name = possible_timestamp_fields.first[:name]
          end
        end
        error('No timestemp request filter field name given') if request_timestamp_field_name.blank?
        request_timestamp_field = request_fields.find do |field|
          field[:name] == request_timestamp_field_name
        end
        if request_timestamp_field.nil?
          error('Could not find timestemp request filter field ' \
                "named '#{request_timestamp_field_name}'")
        end

        # Get since timestamp
        since = (closure&.[]('since') ||
                 input['since'] ||
                 1.hour.ago
                ).to_time

        # set request timestamp
        unless since.nil? || request_timestamp_field.nil?
          case request_timestamp_field[:type]
          when 'string', nil
            request_timestamp_format = filter_input['__timestamp_format']
            # If no format is specified, assume ISO 8601
            request_timestamp_format = '%Y-%m-%dT%H:%M:%S%z' if request_timestamp_format.blank?
            since_formatted = since.strftime(request_timestamp_format)
          when 'date_time'
            # As defined by date-time - RFC3339
            since_formatted = since.strftime('%Y-%m-%dT%H:%M:%S%z')
          when 'date'
            # As defined by full-date - RFC3339
            since_formatted = since.strftime('%Y-%m-%d')
          when 'timestamp', 'integer'
            since_formatted = since.utc.to_i * 1000
          end
          endpoint_input[request_timestamp_field_name] = if since_formatted.nil?
                                                           since
                                                         else
                                                           since_formatted
                                                         end
        end

        request_output = call(
          'execute_action',
          connection,
          endpoint_input,
          'search',
          overwrite_path: overwrite_path
        )

        # get result records
        response_list_field_name = input['record_list_field']
        unless response_list_field_name.present?
          response_list_fields = call(
            'get_search_operation_response_list_fields',
            connection,
            response_fields
          )
          if response_list_fields.present? && response_list_fields.length == 1
            response_list_field_name = response_list_fields.first[:name]
          end
        end
        if response_list_field_name.blank?
          # How is that possible?
          # User should have selected this field in the UI
          error('Cannot find response field for list of records')
        end
        unless request_output.has_key?(response_list_field_name)
          error("Response list field '#{response_list_field_name}' not found")
        end
        result_list = request_output[response_list_field_name]
        unless result_list.is_a?(Array)
          error("Response list field '#{response_list_field_name}' is not a list")
        end

        # get record timestamp field
        records_field = response_fields&.find do |field|
          field[:name] == response_list_field_name
        end
        record_fields = records_field&.[](:properties)
        record_timestamp_field_name = input['record_timestamp_field']
        if record_timestamp_field_name.blank?
          record_timestamp_fields = call(
            'get_record_timestamp_fields',
            connection,
            record_fields
          )
          if record_timestamp_fields&.length == 1
            record_timestamp_field_name = record_timestamp_fields.first[:name]
          end
        end
        error('Timestamp record field name missing') if record_timestamp_field_name.blank?
        record_timestamp_field = record_fields&.find do |field|
          field[:name] == record_timestamp_field_name
        end
        if record_timestamp_field.nil?
          error("cound not find timestamp record field named '#{record_timestamp_field_name}'")
        end
        record_timestamp_field_type = record_timestamp_field[:type]

        # parse timestamp and store in separate key
        result_list = result_list.map do |record|
          timestamp = record[record_timestamp_field_name]

          # TODO: skip if timestamp is already a datetime object
          case record_timestamp_field_type
          when 'string', nil
            record_format = input['record_timestamp_format']
            if record_format.blank?
              timestamp_parsed = timestamp&.to_time
            else
              # TODO: parse string according to format
              #       then do .to_time
              error("custom record timestamp format '#{record_format}' not supported")
            end
          when 'date_time'
            # TODO: check this is as defined by date-time - RFC3339
            timestamp_parsed = timestamp.to_time
          when 'date'
            # TODO: check this is as defined by full-date - RFC3339
            timestamp_parsed = timestamp.to_date.to_time
          when 'timestamp', 'integer'
            timestamp_parsed = (timestamp.to_i / 1000).to_time
          else
            error("unsupported timestamp type: #{record_timestamp_field_type}")
          end
          record.merge('__timestamp_parsed__' => timestamp_parsed)
        end

        # remove records without timestamp
        result_list = result_list.reject do |record|
          record['__timestamp_parsed__'].nil?
        end

        # remove records that are older than 'since'
        result_list = result_list.reject do |record|
          record['__timestamp_parsed__'] < since
        end

        # get latest record timestamp
        latest_timestamp = result_list.map do |record|
          timestamp_parsed = record['__timestamp_parsed__']
          next if timestamp_parsed.nil?

          timestamp_parsed
        end.compact.max

        latest_timestamp = latest_timestamp || since

        # prepare next poll closure
        next_poll = {
          '__poll_time__' => now
        }

        # handle pagination
        can_poll_more = false
        case pagination_mode
        when 'cursor'
          if request_output[cursor_response_field_name].present?
            next_poll['cursor'] = request_output[cursor_response_field_name]
            next_poll['since'] = since
            can_poll_more = true
          else
            next_poll['since'] = latest_timestamp
          end
        when 'next_link'
          if request_output[cursor_next_link_field_name].present?
            next_poll['next_link'] = request_output[cursor_next_link_field_name]
            next_poll['since'] = since
            can_poll_more = true
          else
            next_poll['since'] = latest_timestamp
          end
        when nil # no pagination mode
          # adding 1 second to ensure we don't get the same records again
          # this is not ideal, but it's the best we can do without
          # a proper pagination mechanism provided by the API
          next_poll['since'] = latest_timestamp + 1.second
          page_size = closure&.[]('page_size')
          # if this is the first page OR previous page size is smaller
          # than this page size, update page size for next poll
          page_size = result_list.length if page_size.nil? || page_size < result_list.length
          next_poll['page_size'] = page_size
          # indicate there is more to poll of number is records is smaller than previous page size
          can_poll_more = true if result_list.length == page_size && page_size > 0
        else
          error("unsupported pagination mode: #{pagination_mode}")
        end

        # calculate dedup key
        record_identifier_field_name = input['record_identifier_field']
        if record_identifier_field_name.blank?
          possible_identifier_fields = call(
            'get_record_identifier_fields',
            connection,
            records_field[:properties]
          )
          if possible_identifier_fields&.length == 1
            record_identifier_field_name = possible_identifier_fields.first[:name]
          else
            error('Internal error: Expected to find exactly 1 record identifier field ' \
                  "(got #{possible_identifier_fields})")
          end
        end
        events = result_list.map do |record|
          record_identifier = record[record_identifier_field_name]&.to_s
          record_identifier = workato.uuid.to_s if record_identifier.blank?
          record.merge(
            {
              internal_dedupe_id: "#{record_identifier}-#{record['__timestamp_parsed__']}"
            }
          )
        end

        # return events and next poll info
        {
          events: call('format_response', events),
          next_poll: next_poll,
          can_poll_more: can_poll_more
        }.compact
      end,
      dedup: lambda do |record|
        record['internal_dedupe_id']
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['new_or_updated_record_output']
      end
    },

    new_or_updated_record_batch: {
      title: 'New/updated record (Batch)',
      help: lambda do |_input, _picklist_label|
        {
          body: 'Triggers when a record of the selected object is created/updated (Batch). ' \
                'The list of objects is dynamically generated based on the API endpoints ' \
                'found in the OpenAPI document. ' \
                '<br><br>' \
                'After selecting the object from the picklist, all the required ' \
                'information for handling time-ranges and pagination will be ' \
                'auto-detected from OpenAPI schema definition. ' \
                'In some cases, you may need to manually provide additional information.'
        }
      end,
      subtitle: 'Triggers when selected object is created/updated (Batch)',
      description: lambda do |_input, picklist_label|
        object = picklist_label['object_for_new_or_updated_trigger'] || 'record'
        "New/updated <span class='provider'>#{object}" \
          "</span> via <span class='provider'>OpenAPI (Batch)</span>"
      end,
      input_fields: lambda do |object_definitions|
        object_definitions['new_or_updated_record_input']
      end,
      poll: lambda do |connection, input, closure|
        input = call('format_payload', input)
        connection = call('adjust_connection', connection, input)
        endpoint = call('get_endpoint', connection, input, 'new_or_updated_trigger')
        request_fields = call(
          'request_fields',
          connection,
          endpoint
        )
        response_fields = call(
          'response_fields',
          connection,
          'search',
          endpoint
        )

        filter_input = input['filter'] || {}

        # prepare the 'search' action input
        endpoint_input = {
          'object_for_search' => endpoint.to_json
        }
        # NOTE: when adding new config-fields make sure they are excluded here
        app_filter_values = filter_input.except(
          '__timestamp_field',
          '__timestamp_format'
        )
        endpoint_input = endpoint_input.merge(app_filter_values) if app_filter_values.present?

        # Get pagination mode
        pagination_input = input['pagination'] || {}
        pagination_mode = pagination_input['mode']
        possible_pagination_modes = []
        cursor_request_fields = call(
          'get_cursor_pagination_request_fields',
          connection,
          request_fields
        )
        cursor_response_fields = call(
          'get_cursor_pagination_response_fields',
          connection,
          response_fields
        )
        if cursor_request_fields.present? && cursor_response_fields.present?
          possible_pagination_modes << 'cursor'
        end
        next_link_response_fields = call(
          'get_next_link_pagination_response_fields',
          connection,
          response_fields
        )
        possible_pagination_modes << 'next_link' if next_link_response_fields.present?
        if possible_pagination_modes.length == 1
          pagination_mode_default = possible_pagination_modes.first
        end
        if pagination_mode.blank? && pagination_mode_default.present?
          pagination_mode = pagination_mode_default
        end

        # Handle cursor pagination
        cursor_request_field_name = pagination_input['cursor_request_field']
        cursor_response_field_name = pagination_input['cursor_response_field']
        if pagination_mode == 'cursor'
          if cursor_request_field_name.blank? && cursor_request_fields&.length == 1
            cursor_request_field_name = cursor_request_fields&.first&.[](:name)
          end
          error('Cursor pagination requires request field') if cursor_request_field_name.blank?
          if cursor_response_field_name.blank? && cursor_response_fields&.length == 1
            cursor_response_field_name = cursor_response_fields&.first&.[](:name)
          end
          error('Cursor pagination requires response field') if cursor_response_field_name.blank?
          if closure&.has_key?('cursor')
            endpoint_input[cursor_request_field_name] = closure['cursor']
          end
        end

        # Handle next-link pagination
        cursor_next_link_field_name = pagination_input['next_link_field']
        if pagination_mode == 'next_link'
          if cursor_next_link_field_name.blank? && next_link_response_fields&.length == 1
            cursor_next_link_field_name = next_link_response_fields&.first&.[](:name)
          end
          if cursor_next_link_field_name.blank?
            error('Next-link pagination requires response field')
          end
          overwrite_path = closure['next_link'] if closure&.[]('next_link').present?
        end

        # Get return timestamp field
        request_timestamp_field_name = filter_input['__timestamp_field']
        if request_timestamp_field_name.blank?
          possible_timestamp_fields = call(
            'get_timestamp_request_fields',
            connection,
            request_fields
          )
          if possible_timestamp_fields&.length == 1
            request_timestamp_field_name = possible_timestamp_fields.first[:name]
          end
        end
        error('No timestemp request filter field name given') if request_timestamp_field_name.blank?
        request_timestamp_field = request_fields.find do |field|
          field[:name] == request_timestamp_field_name
        end
        if request_timestamp_field.nil?
          error('Could not find timestemp request filter field ' \
                "named '#{request_timestamp_field_name}'")
        end

        # Get since timestamp
        since = (closure&.[]('since') ||
                 input['since'] ||
                 1.hour.ago
                ).to_time

        # set request timestamp
        unless since.nil? || request_timestamp_field.nil?
          case request_timestamp_field[:type]
          when 'string', nil
            request_timestamp_format = filter_input['__timestamp_format']
            # If no format is specified, assume ISO 8601
            request_timestamp_format = '%Y-%m-%dT%H:%M:%S%z' if request_timestamp_format.blank?
            since_formatted = since.strftime(request_timestamp_format)
          when 'date_time'
            # As defined by date-time - RFC3339
            since_formatted = since.strftime('%Y-%m-%dT%H:%M:%S%z')
          when 'date'
            # As defined by full-date - RFC3339
            since_formatted = since.strftime('%Y-%m-%d')
          when 'timestamp', 'integer'
            since_formatted = since.utc.to_i * 1000
          end
          endpoint_input[request_timestamp_field_name] = if since_formatted.nil?
                                                           since
                                                         else
                                                           since_formatted
                                                         end
        end

        request_output = call(
          'execute_action',
          connection,
          endpoint_input,
          'search',
          overwrite_path: overwrite_path
        )

        # get result records
        response_list_field_name = input['record_list_field']
        unless response_list_field_name.present?
          response_list_fields = call(
            'get_search_operation_response_list_fields',
            connection,
            response_fields
          )
          if response_list_fields.present? && response_list_fields.length == 1
            response_list_field_name = response_list_fields.first[:name]
          end
        end
        if response_list_field_name.blank?
          # How is that possible?
          # User should have selected this field in the UI
          error('Cannot find response field for list of records')
        end
        unless request_output.has_key?(response_list_field_name)
          error("Response list field '#{response_list_field_name}' not found")
        end
        result_list = request_output[response_list_field_name]
        unless result_list.is_a?(Array)
          error("Response list field '#{response_list_field_name}' is not a list")
        end

        # get record timestamp field
        records_field = response_fields&.find do |field|
          field[:name] == response_list_field_name
        end
        record_fields = records_field&.[](:properties)
        record_timestamp_field_name = input['record_timestamp_field']
        if record_timestamp_field_name.blank?
          record_timestamp_fields = call(
            'get_record_timestamp_fields',
            connection,
            record_fields
          )
          if record_timestamp_fields&.length == 1
            record_timestamp_field_name = record_timestamp_fields.first[:name]
          end
        end
        error('Timestamp record field name missing') if record_timestamp_field_name.blank?
        record_timestamp_field = record_fields&.find do |field|
          field[:name] == record_timestamp_field_name
        end
        if record_timestamp_field.nil?
          error("cound not find timestamp record field named '#{record_timestamp_field_name}'")
        end
        record_timestamp_field_type = record_timestamp_field[:type]

        # parse timestamp and store in separate key
        result_list = result_list.map do |record|
          timestamp = record[record_timestamp_field_name]

          # TODO: skip if timestamp is already a datetime object
          case record_timestamp_field_type
          when 'string', nil
            record_format = input['record_timestamp_format']
            if record_format.blank?
              timestamp_parsed = timestamp&.to_time
            else
              # TODO: parse string according to format
              #       then do .to_time
              error("custom record timestamp format '#{record_format}' not supported")
            end
          when 'date_time'
            # TODO: check this is as defined by date-time - RFC3339
            timestamp_parsed = timestamp.to_time
          when 'date'
            # TODO: check this is as defined by full-date - RFC3339
            timestamp_parsed = timestamp.to_date.to_time
          when 'timestamp', 'integer'
            timestamp_parsed = (timestamp.to_i / 1000).to_time
          else
            error("unsupported timestamp type: #{record_timestamp_field_type}")
          end
          record.merge('__timestamp_parsed__' => timestamp_parsed)
        end

        # remove records without timestamp
        result_list = result_list.reject do |record|
          record['__timestamp_parsed__'].nil?
        end

        # remove records that are older than 'since'
        result_list = result_list.reject do |record|
          record['__timestamp_parsed__'] < since
        end

        # get latest record timestamp
        latest_timestamp = result_list.map do |record|
          timestamp_parsed = record['__timestamp_parsed__']
          next if timestamp_parsed.nil?

          timestamp_parsed
        end.compact.max

        latest_timestamp = latest_timestamp || since

        # prepare next poll closure
        next_poll = {
          '__poll_time__' => now
        }

        # handle pagination
        can_poll_more = false
        case pagination_mode
        when 'cursor'
          if request_output[cursor_response_field_name].present?
            next_poll['cursor'] = request_output[cursor_response_field_name]
            next_poll['since'] = since
            can_poll_more = true
          else
            next_poll['since'] = latest_timestamp
          end
        when 'next_link'
          if request_output[cursor_next_link_field_name].present?
            next_poll['next_link'] = request_output[cursor_next_link_field_name]
            next_poll['since'] = since
            can_poll_more = true
          else
            next_poll['since'] = latest_timestamp
          end
        when nil # no pagination mode
          # adding 1 second to ensure we don't get the same records again
          # this is not ideal, but it's the best we can do without
          # a proper pagination mechanism provided by the API
          next_poll['since'] = latest_timestamp + 1.second
          page_size = closure&.[]('page_size')
          # if this is the first page OR previous page size is smaller
          # than this page size, update page size for next poll
          page_size = result_list.length if page_size.nil? || page_size < result_list.length
          next_poll['page_size'] = page_size
          # indicate there is more to poll of number is records is smaller than previous page size
          can_poll_more = true if result_list.length == page_size && page_size > 0
        else
          error("unsupported pagination mode: #{pagination_mode}")
        end

        # calculate dedup key
        record_identifier_field_name = input['record_identifier_field']
        if record_identifier_field_name.blank?
          possible_identifier_fields = call(
            'get_record_identifier_fields',
            connection,
            records_field[:properties]
          )
          if possible_identifier_fields&.length == 1
            record_identifier_field_name = possible_identifier_fields.first[:name]
          else
            error('Internal error: Expected to find exactly 1 record identifier field ' \
                  "(got #{possible_identifier_fields})")
          end
        end
        if result_list.present?
          dedupe_id1 = if result_list&.dig(0, 'record_identifier_field_name').present?
                         "#{result_list&.dig(0, 'record_identifier_field_name')}@#{result_list&.dig(0, '__timestamp_parsed__')}"
                       else
                         "#{workato.uuid}@#{result_list&.dig(0, '__timestamp_parsed__')}"
                       end
          dedupe_id2 = if result_list&.dig(-1, 'record_identifier_field_name').present?
                         "#{result_list&.dig(-1, 'record_identifier_field_name')}@#{result_list&.dig(-1, '__timestamp_parsed__')}"
                       else
                         "#{workato.uuid}@#{result_list&.dig(-1, '__timestamp_parsed__')}"
                       end
          events = [{ 'internal_dedupe_id' => "#{dedupe_id1}@#{dedupe_id2}",
                      'list' => result_list }]
        end

        # return events and next poll info
        {
          events: call('format_response', events),
          next_poll: next_poll,
          can_poll_more: can_poll_more
        }.compact
      end,
      dedup: lambda do |record|
        record['internal_dedupe_id']
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['new_or_updated_record_output_batch']
      end
    }
  },

  pick_lists: {
    tag: lambda do |connection, **input|
      connection = call('adjust_connection', connection, input)
      api_definition = call('get_api_definition', connection)
      tags = call('get_endpoint_tags', api_definition)
      tags.map do |tag|
        [
          call('labelize', tag[:name]),
          tag[:name]
        ]
      end
    end,

    object_for_get: lambda do |connection, **input|
      connection = call('adjust_connection', connection, input)
      call('build_endpoint_pick_list', connection, 'get', nil)
    end,

    object_for_create: lambda do |connection, **input|
      connection = call('adjust_connection', connection, input)
      call('build_endpoint_pick_list', connection, 'create', nil)
    end,

    object_for_update: lambda do |connection, **input|
      connection = call('adjust_connection', connection, input)
      call('build_endpoint_pick_list', connection, 'update', nil)
    end,

    object_for_delete: lambda do |connection, **input|
      connection = call('adjust_connection', connection, input)
      call('build_endpoint_pick_list', connection, 'delete', nil)
    end,

    object_for_search: lambda do |connection, **input|
      connection = call('adjust_connection', connection, input)
      call('build_endpoint_pick_list', connection, 'search', nil)
    end,

    object_for_new_or_updated_trigger: lambda do |connection, **input|
      connection = call('adjust_connection', connection, input)
      call('build_endpoint_pick_list', connection, 'new_or_updated_trigger', nil)
    end,

    operation: lambda do |connection, **input|
      connection = call('adjust_connection', connection, input)
      call('build_endpoint_pick_list', connection, 'execute', nil)
    end,

    operation_filtered: lambda do |connection, tag:, **input|
      connection = call('adjust_connection', connection, input)
      tag = nil if tag.blank? || tag == '-' # keep '-' for backwards compatibility
      call('build_endpoint_pick_list', connection, 'execute', tag)
    end
  },

  methods: {

    adjust_connection: lambda do |connection, input|
      connection
    end,

    handle_api_error: lambda do |request|
      request.after_error_response('.*') do |_code, body, header, message|
        content_type = header['content_type'] || ''
        if content_type.include?('application/json')
          response = workato.parse_json(body)
          response = response.first if response.is_a?(Array)
          if response.is_a?(Hash)
            message = response['message']
            message = response['Message'] if message.blank?
            if message.blank? && response['messages'].is_a?(Array) && response['messages'].present?
              message = response['messages'].join(', ')
            end
            if message.blank? && response['messages'].is_a?(Hash) && response['messages'].present?
              message = response['messages']
            end
            message = response['error'] if message.blank?
            message = response['Error'] if message.blank?
            if message.blank? && response['errors'].is_a?(Array) && response['errors'].present?
              message = response['errors'].join(', ')
            end
            if message.blank? && response['errors'].is_a?(Hash) && response['errors'].present?
              message = response['errors']
            end
            message = response['reason'] if message.blank?
            message = response['Reason'] if message.blank?
            message = response['description'] if message.blank?
            message = response['Description'] if message.blank?
            error(message.to_s) unless message.blank?
          end
        end
        error("#{message}: #{body}")
      end
    end,

    execute_action: lambda do |connection, input, verb, overwrite_path:|
      input = call('format_payload', input)

      endpoint = call('get_endpoint', connection, input, verb)
      error("#{verb} endpoint missing") if endpoint.nil?

      schema = endpoint['schema']
      error('endpoint schema missing') if schema.nil?

      openapi_version = endpoint['openapi_version']
      method_prefix = call('get_openapi_version_method_prefix', openapi_version)

      if overwrite_path.present?
        path = overwrite_path
      else
        # path parameters
        path = endpoint['path']
        path_parameters = schema['parameters']&.select do |parameter|
          parameter['in'] == 'path'
        end || []
        missing_path_fields = path.scan(/{([^}]+)}/)&.map do |name,|
          path_parameter = schema['parameters']&.find do |f|
            f[:name] == name
          end
          next unless path_parameter.nil?

          {
            'in' => 'path',
            'name' => name,
            'schema' => { 'type' => 'string' },
            'required' => true,
            'optional' => false
          }
        end&.compact # add missing
        path_parameters = missing_path_fields + path_parameters if missing_path_fields.present?
        path_parameters.each do |parameter|
          name = parameter['name']
          value = input[name]
          value = value.to_s unless value.nil?
          error("path parameter '#{name}' missing") if value.blank?
          path = path.gsub("{#{name}}", value.encode_url)
        end

        # query string parameters
        query_string = call(
          "#{method_prefix}execute_action_get_query_string",
          connection, schema['parameters'], input
        )
        path = "#{path}?#{query_string}" unless query_string.blank?
      end

      # TODO: add cookie support

      # strip leading slash from path to support
      # non-root base paths
      path = path[1..-1] if path.starts_with?('/')

      # replacing the : to %3A in url alone.
      path = path.gsub(':', '%3A')

      # appending action level server url
      path = "#{input['base_url']}/#{path}" if input['base_url'].present?

      # build request based on method
      case endpoint['method']
      when 'get'
        request = get(path)
      when 'patch'
        request = patch(path)
      when 'post'
        request = post(path)
      when 'delete'
        request = delete(path)
      when 'put'
        request = put(path)
      else
        error("unexpected HTTP method: #{endpoint}")
      end

      # add request header parameters
      request_headers = {}
      schema['parameters']&.each do |parameter|
        next unless parameter['in'] == 'header'

        name = parameter['name']
        value = input[name]
        request_headers[name] = value if value.present?
      end
      request.case_sensitive_headers(request_headers) if request_headers.present?

      # add request body (incl. content type)
      request_media_type = endpoint['request_media_type']
      unless request_media_type.blank?
        request = request.headers('Content-Type' => request_media_type)
        request = call(
          "#{method_prefix}execute_action_add_request_body",
          input, endpoint, request
        )
      end

      # process response
      expected_response_media_type = endpoint['response_media_type']
      unless expected_response_media_type.blank?
        request = request.headers('Accept' => expected_response_media_type)
        if expected_response_media_type == 'application/octet-stream'
          request = request.response_format_raw
        end
        request = request.response_format_json if expected_response_media_type.include? 'json'
      end
      request = call('handle_api_error', request)
      request.after_response do |_code, body, response_headers|
        actual_response_media_type = response_headers[:content_type]
        if expected_response_media_type != actual_response_media_type &&
           actual_response_media_type&.include?('json') &&
           body.is_a?(String)
          body = workato.parse_json(body)
        end
        output_from_response = call(
          "#{method_prefix}action_output_from_response",
          endpoint,
          body
        )
        call('format_response', output_from_response)
      end
    end,

    openapi_v2_action_output_from_response: lambda do |endpoint, response|
      endpoint_schema = endpoint['schema']
      expected_response_name = endpoint['expected_response_name']
      response_schema = endpoint_schema.dig(
        'responses',
        expected_response_name,
        'schema'
      )

      unless response_schema.nil?
        response = call(
          'openapi_v2_get_output_value',
          response_schema,
          response
        )
      end

      if response.is_a?(Hash)
        response
      else
        { result: response }
      end
    end,

    openapi_v3_action_output_from_response: lambda do |endpoint, response|
      endpoint_schema = endpoint['schema']
      expected_response_name = endpoint['expected_response_name']
      response_media_type = endpoint['response_media_type']
      response_schema = endpoint_schema.dig(
        'responses',
        expected_response_name,
        'content',
        response_media_type,
        'schema'
      )

      unless response_schema.nil?
        response = call(
          'openapi_v3_get_output_value',
          response_schema,
          response
        )
      end

      if response.is_a?(Hash)
        response
      else
        { result: response }
      end
    end,

    openapi_v3_get_output_value: lambda do |schema, value_from_response|
      if schema.has_key?('allOf')
        call(
          'openapi_v3_get_output_value_all_of_composition',
          schema['allOf'],
          value_from_response
        )
      elsif schema.has_key?('oneOf')
        call(
          'openapi_v3_get_output_value_one_of_composition',
          schema['oneOf'],
          value_from_response
        )
      elsif schema.has_key?('anyOf')
        call(
          'openapi_v3_get_output_value_any_of_composition',
          schema['anyOf'],
          value_from_response
        )
      else
        call(
          'openapi_v3_get_output_value_no_composition',
          schema,
          value_from_response
        )
      end
    end,

    openapi_v3_get_output_value_all_of_composition: lambda do |schema_items, value_from_response|
      schema = call(
        'merge_schema_objects',
        schema_items
      )
      call('openapi_v3_get_output_value', schema, value_from_response)
    end,

    openapi_v3_get_output_value_one_of_composition: lambda do |schema_items, value_from_response|
      if schema_items.find { |s| s['type'] == 'object' || s[:type] == 'object' }
        schema = call(
          'merge_schema_objects',
          schema_items
        )
        call('openapi_v3_get_output_value', schema, value_from_response)
      elsif value_from_response.is_a?(Integer)
        {
          ___integer___: value_from_response
        }
      elsif value_from_response.is_a?(Float)
        {
          ___number___: value_from_response
        }
      elsif [true, false].include?(value_from_response)
        {
          ___boolean___: value_from_response
        }
      else
        {
          ___string___: value_from_response
        }
      end
    end,

    openapi_v3_get_output_value_any_of_composition: lambda do |schema_items, value_from_response|
      schema = call(
        'merge_schema_objects',
        schema_items
      )
      call('openapi_v3_get_output_value', schema, value_from_response)
    end,

    openapi_v3_get_output_value_no_composition: lambda do |schema, value_from_response|
      call('fix_schema_type', schema)

      case schema['type']&.to_s&.downcase
      when 'object'
        if value_from_response.is_a?(Hash)
          property_fields = schema['properties']
          additional_properties = schema['additionalProperties']
          additional_properties = true if additional_properties.nil?
          additional_properties = { 'type' => 'string' } if additional_properties == true
          is_key_value_list = (property_fields.nil? || property_fields&.empty?) &&
                              additional_properties != false
          if is_key_value_list
            list = []
            value_from_response.each do |property_name, property_value|
              property_value = call(
                'openapi_v3_get_output_value',
                additional_properties,
                property_value
              )
              list.push({ 'key' => property_name, 'value' => property_value })
            end
            list
          else
            object = {}
            property_fields = property_fields&.select do |property_name, _property_schema|
              value_from_response.has_key?(property_name)
            end
            property_fields&.each do |property_name, property_schema|
              property_value = value_from_response[property_name]
              property_value = call(
                'openapi_v3_get_output_value',
                property_schema,
                property_value
              )
              object[property_name] = property_value
            end
            object
          end
        else
          value_from_response
        end
      when 'array'
        if schema.has_key?('items')
          value_from_response&.map do |item|
            call(
              'openapi_v3_get_output_value',
              schema['items'],
              item
            )
          end
        else
          value_from_response
        end
      else
        value_from_response
      end
    end,

    openapi_v2_execute_action_get_query_string: lambda do |_connection, parameters, input|
      params = {}
      parameters&.each do |parameter|
        next unless parameter['in'] == 'query'

        # TODO: check collectionFormat

        name = parameter['name']
        value = input[name]
        params[name] = value if value.present?
      end
      # not using .params() since it would add '[]' suffix for multi-value parameter names
      params.to_param.gsub(/%5B%5D=/, '=') unless params.empty?
    end,

    openapi_v3_execute_action_get_query_string: lambda do |_connection, parameters, input|
      query_string = ''
      encode_value = lambda do |parameter, value|
        allow_reserved = parameter['allowReserved'] || false
        value = value.to_s
        if allow_reserved
          value
        else
          value.encode_url
        end
      end
      add_param = lambda do |k, v|
        query_string = "#{query_string}&" unless query_string.blank?
        query_string = "#{query_string}#{k}=#{v}"
      end
      parameters&.each do |parameter|
        next unless parameter['in'] == 'query'

        name = parameter['name']
        style = parameter['style'] || 'form'
        explode = if parameter['explode'].nil?
                    style == 'form'
                  else
                    parameter['explode'].is_true?
                  end
        value = call('get_value_from_input', parameter['schema'], input[name])
        if value.is_a?(Hash) && style == 'form' && explode == true
          value.each do |k, v|
            add_param.call(k, encode_value.call(parameter, v))
          end
        elsif value.is_a?(Hash) && style == 'form' && explode == false
          values = []
          value.each do |k, v|
            values.push(k)
            values.push(encode_value.call(parameter, v))
          end
          add_param.call(name, values.join(',')) if values.present?
        elsif value.is_a?(Array) &&
              %w[form spaceDelimited pipeDelimited].include?(style) &&
              explode == true
          value.each do |v|
            add_param.call(name, encode_value.call(parameter, v))
          end
        elsif value.is_a?(Array) && style == 'form' && explode == false
          encoded_values = value.map do |v|
            encode_value.call(parameter, v)
          end
          add_param.call(name, encoded_values.join(',')) if value.present?
        elsif value.is_a?(Array) && style == 'spaceDelimited' && explode == false
          encoded_values = value.map do |v|
            encode_value.call(parameter, v)
          end
          add_param.call(name, encoded_values.join('%20')) if value.present?
        elsif value.is_a?(Array) && style == 'pipeDelimited' && explode == false
          encoded_values = value.map do |v|
            encode_value.call(parameter, v)
          end
          add_param.call(name, encoded_values.join('|')) if value.present?
        elsif value.is_a?(Hash) && style == 'deepObject' && explode == true
          value.each do |k, v|
            add_param.call("#{name}[#{k}]", encode_value.call(parameter, v))
          end
        elsif !value.nil? &&
              !value.is_a?(Array) &&
              !value.is_a?(Hash) &&
              style == 'form'
          add_param.call(name, encode_value.call(parameter, value))
        end
      end
      query_string
    end,

    openapi_v2_execute_action_add_request_body: lambda do |input, endpoint, request|
      request_media_type = endpoint['request_media_type']
      schema = endpoint['schema']

      # request json body
      if request_media_type.include? 'json'
        body_parameter = schema['parameters']&.find { |parameter| parameter['in'] == 'body' }
        unless body_parameter.nil?
          body_value = call('openapi_v2_request_parameter_value', body_parameter, input)
        end
        unless body_value.nil?
          body_value = call(
            'get_value_from_input',
            body_parameter['schema'],
            body_value
          )
          request = if body_value.is_a?(Hash)
                      request.payload(body_value)
                    elsif body_value.is_a?(Array)
                      # this is a workaround for an issue in the cloud
                      # when sending an array using 'payload'
                      # TODO: remove this workaround when the issue is fixed
                      request = request.request_format_json
                      request.request_body(body_value.to_json)
                    else
                      request.request_body(body_value)
                    end
        end
      end

      # request form-data body
      form_data_media_types = [
        'multipart/form-data',
        'application/x-www-form-urlencoded'
      ]
      if form_data_media_types.include? request_media_type
        form_data = {}
        schema['parameters']&.each do |parameter|
          next unless parameter['in'] == 'formData'

          name = parameter['name']
          value = call('openapi_v2_request_parameter_value', parameter, input)
          form_data[name] = value if value.present?
        end
        request = case request_media_type
                  when 'multipart/form-data'
                    request.request_format_multipart_form
                  when 'application/x-www-form-urlencoded'
                    request.request_format_www_form_urlencoded
                  end
        request = request.payload(form_data)
      end

      # TODO: add application/octet-stream support

      request
    end,

    openapi_v3_execute_action_add_request_body: lambda do |input, endpoint, request|
      request_media_type = endpoint['request_media_type']
      if input.has_key?('body')
        body = input['body']
      else
        body = {}
        input.each do |k, v|
          prefix = 'body_object_'
          if k.starts_with?(prefix)
            sub_key = k.last(k.length - prefix.length)
            body[sub_key] = v
          end
        end
      end
      endpoint_schema = endpoint['schema']
      body_schema = endpoint_schema.dig('requestBody', 'content', request_media_type, 'schema')

      # request json body
      if request_media_type.include?('json') && !body.nil?
        body_value = call('get_value_from_input', body_schema, body)
        request = if body_value.is_a?(Hash)
                    request.payload(body_value)
                  elsif body_value.is_a?(Array)
                    # this is a workaround for an issue in the cloud
                    # when sending an array using 'payload'
                    # TODO: remove this workaround when the issue is fixed
                    request = request.request_format_json
                    request.request_body(body_value.to_json)
                  else
                    request.request_body(body_value)
                  end
      end

      # request form-data body
      if request_media_type == 'multipart/form-data' && !body.nil?
        if body.is_a?(Hash)
          body.each do |k, v|
            next unless v.is_a?(Hash)
            next unless v.has_key?('binary')

            file = v['binary']
            mime_type = v['mime_type']
            name = v['name']

            next if file.nil?

            body[k] = [file, mime_type, name].compact
          end
          request = request.request_format_multipart_form
          request = request.payload(body)
        else
          error("unexpected body type (#{body.class})")
        end
      end

      # request form-urlencoded body
      if request_media_type == 'application/x-www-form-urlencoded' && !body.nil?
        body_value = call('get_value_from_input', body_schema, body)
        request = request.payload(body_value).request_format_www_form_urlencoded
      end

      # TODO: add application/octet-stream support

      request
    end,

    get_value_from_input: lambda do |schema, input|
      if schema.has_key?('allOf')
        call(
          'get_value_from_input_all_of_composition',
          schema['allOf'],
          input
        )
      elsif schema.has_key?('oneOf')
        call(
          'get_value_from_input_oneof_of_composition',
          schema['oneOf'],
          input
        )
      elsif schema.has_key?('anyOf')
        call(
          'get_value_from_input_any_of_composition',
          schema['anyOf'],
          input
        )
      else
        call(
          'get_value_from_input_no_composition',
          schema,
          input
        )
      end
    end,

    get_value_from_input_all_of_composition: lambda do |schema_items, input|
      schema = call(
        'merge_schema_objects',
        schema_items
      )
      call('get_value_from_input', schema, input)
    end,

    get_value_from_input_oneof_of_composition: lambda do |schema_items, input|
      # Simply deep merge input schema and type whatever values has been provided
      # This is not compliant with the spec, but it is a reasonable workaround
      schema = call(
        'merge_schema_objects',
        schema_items
      )
      call('get_value_from_input', schema, input)
    end,

    get_value_from_input_any_of_composition: lambda do |schema_items, input|
      # Simply deep merge input schema and type whatever values has been provided
      # This is not compliant with the spec, but it is a reasonable workaround
      schema = call(
        'merge_schema_objects',
        schema_items
      )
      call('get_value_from_input', schema, input)
    end,

    get_value_from_input_no_composition: lambda do |schema, input|
      call('fix_schema_type', schema)

      case schema['type']
      when 'object'
        required_properties = schema['required']
        required_properties = [] unless required_properties.is_a?(Array)
        object = {}
        if input.is_a?(Hash)
          schema['properties']&.each do |property_name, property_schema|
            is_required = required_properties.include?(property_name)
            property_value = input[property_name]
            property_value = call(
              'get_value_from_input',
              property_schema,
              property_value
            )
            # skip null values
            next if property_value.nil?
            # skip if optional empty hash or empty arrays
            next if !is_required &&
                    (
                      (property_value.is_a?(Hash) && !property_value.present?) ||
                      (property_value.is_a?(Array) && !property_value.present?)
                    )

            object[property_name] = property_value
          end
        end
        if input.is_a?(Array)
          property_schema = schema['additionalProperties']
          property_schema = true if property_schema.nil?
          property_schema = { 'type' => 'string' } if property_schema == true
          error('Unexpected array') if property_schema == false
          input.each do |item|
            error('Unexpected item type') unless item.is_a?(Hash)
            error('\'key\' missing') unless item.has_key?('key')
            error('\'value\' missing') unless item.has_key?('value')
            object[item['key']] = call(
              'get_value_from_input',
              property_schema,
              item['value']
            )
          end
        end
        object
      when 'array'
        if schema.has_key?('items') && input.is_a?(Array)
          input&.map do |item|
            call(
              'get_value_from_input',
              schema['items'],
              item
            )
          end
        elsif input.is_a?(String) &&
              input.present? &&
              schema.dig('items', 'type') == 'string' &&
              schema.dig('items', 'enum').present?
          input = input.split(',').map do |item|
            item.strip
          end
        else
          input
        end
      else
        input
      end
    end,

    get_endpoint_hints: lambda do |connection, endpoint|
      operation_schema = endpoint['schema']
      object_hint_field = connection.dig('advanced', 'object_hint_field')
      object_hint_field = connection['object_hint_field'] if object_hint_field.nil?
      if object_hint_field.blank?
        hint_source = operation_schema['description']
        hint_source = operation_schema['summary'] if hint_source.blank?
      else
        hint_source = operation_schema[object_hint_field]
      end
      object_hint_substitutions = connection.dig('advanced', 'object_hint_substitutions')
      if object_hint_substitutions.nil?
        object_hint_substitutions = connection['object_hint_substitutions']
      end
      object_hint_substitutions&.each do |substitution|
        pattern = /#{substitution['pattern']}/
        replacement = substitution['replacement']
        new_hint_source = hint_source&.gsub(pattern, replacement)
        hint_source = new_hint_source unless new_hint_source.blank?
      end
      hint_source = hint_source&.gsub(/^\w/) { |c| c.upcase }
      call(
        'convert_common_mark_to_field_hint_format',
        connection,
        hint_source,
        nil
      )
    end,

    get_action_input_fields: lambda do |connection, input, verb|
      fields = []
      endpoint = call('get_endpoint', connection, input, verb)
      operation_schema = endpoint&.[]('schema')
      if verb == 'execute'
        api_definition = call('get_api_definition', connection)
        unless api_definition.nil?
          tags = call('get_endpoint_tags', api_definition)
          tag_schema = tags.find do |tag|
            tag[:name] == input['tag']
          end
        end
        tag_description = tag_schema[:description] if tag_schema.present?
        fields.push(
          {
            name: 'tag',
            label: 'Filter operations',
            control_type: 'select',
            hint: tag_description || 'Select an item to filter the list of operations.',
            pick_list: 'tag',
            pick_list_params: {
              # definition_mode: 'definition_mode',
              # definition_url: 'definition_url',
              # definition_content: 'definition_content'
            },
            extends_schema: true,
            schema_neutral: false,
            optional: true
          }
        )
        if input['tag'].blank?
          pick_list = 'operation'
        else
          pick_list = 'operation_filtered'
          pick_list_params = {
            tag: 'tag',
            # definition_mode: 'definition_mode',
            # definition_url: 'definition_url',
            # definition_content: 'definition_content'
          }
        end
        picklist_hint = 'Select any operation.'
        fields.push(
          {
            name: 'operation_label',
            label: 'Operation name',
            type: 'string',
            control_type: 'text',
            hint: 'Customize this operation by providing a more descriptive name.',
            optional: true,
            extends_schema: true,
            schema_neutral: false
          }
        )
      else
        pick_list = "object_for_#{verb}"
        picklist_hint = 'Select any object.'
        pick_list_params = {
          # definition_mode: 'definition_mode',
          # definition_url: 'definition_url',
          # definition_content: 'definition_content'
        }
      end
      endpoint_hint = call('get_endpoint_hints', connection, endpoint) unless endpoint.nil?
      endpoint_title = endpoint&.[]('title')
      if endpoint_hint.present? && endpoint_title.present? &&
         endpoint_title != endpoint_hint
        picklist_hint = endpoint_hint
      end
      fields.push(
        {
          name: "object_for_#{verb}",
          label: verb == 'execute' ? 'Operation' : 'Object',
          hint: picklist_hint,
          control_type: 'select',
          pick_list: pick_list,
          pick_list_params: pick_list_params,
          extends_schema: true,
          schema_neutral: false,
          optional: false,
          sticky: true
        }.compact
      )

      # Allow user to select expected response API response "name" (typically HTTP status code)
      if %w[execute create update delete].include?(verb) && operation_schema.present?
        default_expected_response_name = call(
          'get_default_expected_response_name',
          operation_schema,
          verb
        )
        possible_responses = []
        operation_schema['responses'].each do |name, response|
          # skip responses with status code < 200
          code = name.to_i
          next if !code.nil? && code < 200

          is_default = default_expected_response_name == name

          # use description as label if present, otherwise use name
          response_description = response['description']
          label = if response_description.present?
                    if is_default
                      "#{response_description} (#{name})"
                    else
                      "#{response_description} (#{name}, default)"
                    end
                  elsif is_default
                    "#{name} (default)"
                  else
                    name
                  end

          possible_responses << [label, name]
        end

        # only add input field if there is something for users to pick from
        if possible_responses.present? && possible_responses.length > 1
          fields.push(
            {
              name: 'expected_response_name',
              label: 'Expected response',
              type: 'string',
              control_type: 'select',
              optional: true,
              hint: 'Response schema will be used to generate the recipe datapills. ' \
                    "Defaults to #{default_expected_response_name}.",
              pick_list: possible_responses,
              extends_schema: true,
              schema_neutral: false
            }
          )
        end
      end

      unless operation_schema.nil?
        fields.concat(
          call(
            'request_fields',
            connection,
            endpoint
          )
        )
      end
      call('format_schema', fields)
    end,

    add_toggel_fields: lambda do |fields|
      fields&.map do |field|
        if %w[multiselect select checkbox].include? field[:control_type]
          toggle_field_label = field[:label]
          toggle_field_label = call('labelize', field[:name]) if toggle_field_label.blank?
          if field[:control_type] == 'checkbox' && field[:type] == 'boolean'
            base_field_hint = field[:hint]&.strip
            base_field_hint = base_field_hint[0..-2] if base_field_hint&.ends_with?('.')
            unless base_field_hint.blank?
              toggle_field_hint = "#{base_field_hint}. Allowed values are true or false."
            end
          end
          if field[:control_type] == 'multiselect' && field[:type] == 'string'
            base_field_hint = field[:hint]&.strip
            base_field_hint = base_field_hint[0..-2] if base_field_hint&.ends_with?('.')
            unless base_field_hint.blank?
              toggle_field_hint = "#{base_field_hint}. " \
                                  "Multiple value can be separated using comma (',')"
            end
          end
          field.merge(
            {
              toggle_hint: 'Select from list',
              toggle_field: field.except('pick_list').merge(
                {
                  label: toggle_field_label,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: toggle_field_hint
                }.compact
              )
            }
          )
        else
          field.merge(
            {
              properties: call('add_toggel_fields', field[:properties])
            }.compact
          )
        end
      end
    end,

    request_fields: lambda do |connection, endpoint|
      api_definition = call('get_api_definition', connection)
      openapi_version = call('get_openapi_version', api_definition)
      request_media_type = endpoint['request_media_type']
      path = endpoint['path']
      operation_schema = endpoint['schema']

      prefix = call('get_openapi_version_method_prefix', openapi_version)
      fields = call(
        "#{prefix}request_fields",
        connection,
        operation_schema,
        request_media_type
      )

      # add missing path parameters
      missing_path_fields = path.scan(/{([^}]+)}/)&.map do |name,|
        field = fields.find do |f|
          f[:name] == name
        end
        next unless field.nil?

        {
          name: name,
          type: 'string',
          optional: false
        }
      end&.compact
      fields = missing_path_fields + fields if missing_path_fields.present?

      fields = call('add_toggel_fields', fields)

      ignore_request_fields = connection.dig('advanced', 'ignore_request_fields')
      ignore_request_fields = connection['ignore_request_fields'] if ignore_request_fields.nil?
      ignore_request_fields&.each do |ignore_request_field|
        names = ignore_request_field['path']&.split('.')
        node = fields
        names&.each_with_index do |name, index|
          field = node&.find do |f|
            f[:name] == name
          end
          node = nil if field.nil?
          if index == names.length - 1
            node&.delete(field)
          else
            node = field&.[](:properties)
          end
        end
      end

      call('make_all_fields_non_sticky', fields) if call('has_required_fields', fields)
      fields
    end,

    has_required_fields: lambda do |fields|
      is_required = false
      fields&.each do |field|
        next if is_required

        is_required = (field[:optional] == false)
        next if is_required

        is_required = call('has_required_fields', field[:properties])
      end
      is_required
    end,

    make_all_fields_non_sticky: lambda do |fields|
      fields&.each do |field|
        if field[:optional].nil? || field[:optional] == true
          field.delete(:sticky)
          field[:toggle_field]&.delete(:sticky)
        end
        call('make_all_fields_non_sticky', field[:properties])
      end
    end,

    openapi_v2_request_fields: lambda do |connection, endpoint_schema,
                                          _request_media_type|
      parameters = endpoint_schema['parameters'] || []
      parameters.map do |parameter|
        # sometimes parameter definitions contain type information
        # (no need to call fix_schema_type)
        parameter_type = parameter['type']&.to_s&.downcase
        case parameter_type
        when 'boolean', 'bool'
          field_type = 'boolean'
          control_type = 'checkbox'
          render_input = 'boolean_conversion'
          parse_output = 'boolean_conversion'
        when 'string'
          field_type = 'string'
          control_type = 'text'
        when 'integer'
          field_type = 'integer'
          control_type = 'integer'
          render_input = 'integer_conversion'
          parse_output = 'integer_conversion'
        when 'number'
          field_type = 'number'
          control_type = 'number'
          render_input = 'float_conversion'
          parse_output = 'float_conversion'
        when 'array'
          field_type = 'array'
          items_field = call('openapi_v2_schema_field', connection,
                             parameter['items'], true)
          array_items_type = items_field[:type]
          property_fields = items_field[:properties]
        when 'file'
          field_type = 'string'
          control_type = 'text-area'
        when 'application/json'
          # do nothing
        else
          unless parameter['type'].nil?
            error("unexpected type '#{parameter_type}' in parameter: #{parameter}")
          end
        end

        schema = parameter['schema'] || {}
        field = call('openapi_v2_schema_field', connection, schema, true) unless schema.empty?
        field = {} if field.nil?

        optional = false if parameter['in'] == 'path'
        optional = !parameter['required'] if optional.nil?

        field_hint = call(
          'convert_common_mark_to_field_hint_format',
          connection,
          parameter['description'],
          nil
        )

        field = field.merge({
          name: parameter['name'],
          type: field_type,
          label: call('labelize', parameter['name']),
          optional: optional,
          sticky: true,
          control_type: control_type,
          hint: field_hint,
          default: parameter['default'],
          properties: property_fields,
          of: array_items_type,
          render_input: render_input,
          parse_output: parse_output
        }.compact)

        if parameter['in'] == 'body'
          if field[:type] == 'object'
            (field[:properties] || []).map do |property|
              property[:label] = call('labelize', property[:name])
              property[:name] = "#{field[:name]}_#{property[:name]}"
              property
            end
          else
            field[:label] = 'Value'
            [field]
          end
        else
          [field]
        end
      end.flatten(1)
    end,

    openapi_v3_request_fields: lambda do |connection, endpoint_schema,
                                          request_media_type|
      parameters = endpoint_schema['parameters'] || []
      fields_array = parameters.map do |parameter|
        field = if parameter.has_key? 'schema'
                  call(
                    'openapi_v3_schema_field',
                    connection,
                    parameter['schema'],
                    true
                  )
                else
                  {}
                end

        optional = false if parameter['in'] == 'path'
        optional = !parameter['required'] if optional.nil?

        # address yaml parser behaviour:
        #   parameter names 'on' and 'off' are converted to boolean values
        unless parameter['name'].is_a?(String)
          parameter['name'] = if parameter['name'].to_s == 'true'
                                'on'
                              else
                                'off'
                              end
        end

        # compose field hint based on description and example values
        field_hint = call(
          'convert_common_mark_to_field_hint_format',
          connection,
          parameter['description'],
          nil
        )
        if parameter['examples']&.present?
          example_value = call(
            'openapi_v3_example_object_map_value',
            parameter['examples']
          )
        end
        example_value = parameter['example'] if example_value.blank?
        if example_value.blank? && parameter.has_key?('schema')
          example_value = call(
            'openapi_v3_schema_object_example_value',
            parameter['schema']
          )
        end
        if example_value.present? &&
           field[:control_type] != 'multiselect' &&
           field[:control_type] != 'select'
          field_hint = if field_hint.blank?
                         'E.g.'
                       elsif field_hint.ends_with?('.')
                         "#{field_hint} E.g."
                       else
                         "#{field_hint}, e.g."
                       end
          field_hint = "#{field_hint} #{example_value}"
        end

        field.merge({
          name: parameter['name'],
          label: call('labelize', parameter['name']),
          optional: optional,
          hint: field_hint
        }.compact)
      end

      ## add fields for request body
      request_schema = endpoint_schema.dig('requestBody', 'content', request_media_type, 'schema')
      if request_schema.present?
        field = call('openapi_v3_schema_field', connection, request_schema, true)
        if field[:type] == 'object'
          field[:properties]&.each do |f|
            f[:label] = call('labelize', f[:name])
            f[:name] = "body_object_#{f[:name]}"
            fields_array.push(f)
          end
        else
          field[:name] = 'body'
          fields_array.push(field)
        end
      end
      fields_array
    end,

    get_default_expected_response_name: lambda do |operation, verb|
      responses = operation['responses'] || {}
      # rubocop:disable Lint/DuplicateBranch
      if %w[get list delete search new_or_updated_trigger].include? verb
        if responses.has_key?('200') && responses.dig('200', 'schema').present?
          '200'
        elsif responses.has_key?('204') && responses.dig('204', 'schema').present?
          '204'
        elsif responses.has_key?('default') && responses.dig('default', 'schema').present?
          'default'
        elsif responses.has_key?('200')
          '200'
        elsif responses.has_key?('204')
          '204'
        elsif responses.has_key?('default')
          'default'
        end
      elsif %w[execute update create].include? verb
        if responses.has_key?('201') && responses.dig('201', 'schema').present?
          '201'
        elsif responses.has_key?('200') && responses.dig('200', 'schema').present?
          '200'
        elsif responses.has_key?('202') && responses.dig('202', 'schema').present?
          '202'
        elsif responses.has_key?('default') && responses.dig('default', 'schema').present?
          'default'
        elsif responses.has_key?('201')
          '201'
        elsif responses.has_key?('200')
          '200'
        elsif responses.has_key?('202')
          '202'
        elsif responses.has_key?('default')
          'default'
        end
      else
        error("unexpected verb: #{verb}")
      end
      # rubocop:enable Lint/DuplicateBranch
    end,

    get_action_output_fields: lambda do |connection, input, verb|
      endpoint = call('get_endpoint', connection, input, verb)
      if endpoint.present?
        response_fields = call(
          'response_fields',
          connection,
          verb,
          endpoint
        )
        call('format_schema', response_fields)
      else
        []
      end
    end,

    get_response_field_label: lambda do |verb, endpoint|
      title = endpoint['title']
      case verb
      when 'search'
        if title.include? ' '
          title
        else
          title.pluralize
        end
      when 'get'
        title
      end
    end,

    response_fields: lambda do |connection, verb, endpoint|
      operation_schema = endpoint['schema']
      expected_response_name = endpoint['expected_response_name']
      unless expected_response_name.blank?
        response_object = operation_schema.dig('responses', expected_response_name)
      end
      openapi_version = endpoint['openapi_version']
      prefix = call('get_openapi_version_method_prefix', openapi_version)
      if response_object.present?
        call(
          "#{prefix}response_fields",
          connection,
          verb,
          response_object,
          endpoint
        )
      end
    end,

    openapi_v2_response_fields: lambda do |connection, verb,
                                           response_object, endpoint|
      # some v2 responses define type information (should not be the case)
      case response_object['type']&.to_s&.downcase
      when 'object'
        field_type = 'object'
      when 'boolean', 'bool'
        field_type = 'boolean'
      when 'string'
        field_type = 'string'
      when 'integer'
        field_type = 'integer'
      when 'number'
        field_type = 'number'
      when 'array'
        field_type = 'array'
        items_field = call('openapi_v2_schema_field', connection,
                           response_object['items'], false)
        array_items_type = items_field[:type]
        property_fields = items_field[:properties]
      else
        error("unexpected type in response: #{response_object}") unless response_object['type'].nil?
      end
      schema = response_object['schema'] || {}
      unless schema.empty?
        response_field = call('openapi_v2_schema_field', connection, schema, false)
      end
      response_field = {} if response_field.nil?
      if response_field[:type] == 'object'
        response_field[:properties]&.each do |field|
          if field[:name] == 'resources' && verb == 'search' # TODO: move this to calling method
            field[:label] = call('get_response_field_label', verb, endpoint)
          end
        end
      elsif response_field.present?
        field_hint = call(
          'convert_common_mark_to_field_hint_format',
          connection,
          response_object['description'],
          nil
        )
        [response_field.merge({
          name: 'result',
          label: call('get_response_field_label', verb, endpoint), # TODO: remove
          type: field_type,
          hint: field_hint,
          properties: property_fields,
          of: array_items_type
        }.compact)]
      end
    end,

    openapi_v3_response_fields: lambda do |connection, verb,
                                           response_object, endpoint|
      schema_object = response_object.dig(
        'content',
        endpoint['response_media_type'],
        'schema'
      )
      if schema_object.nil?
        []
      else
        field = call('openapi_v3_schema_field', connection, schema_object, false)
        if field[:type] == 'object'
          field[:properties]&.map do |f|
            if f[:name] == 'resources' && verb == 'search' # TODO: move this to calling method
              f[:label] = call('get_response_field_label', verb, endpoint)
            end
            f
          end || []
        elsif field.present?
          [field.merge({
            name: 'result',
            label: call('get_response_field_label', verb, endpoint) # TODO: remove
          }.compact)]
        end
      end
    end,

    fix_schema_type: lambda do |schema|
      # convert to string if type is not a string
      if schema['type'].present? && !schema['type'].is_a?(String)
        schema['type'] = schema['type'].to_s
      end

      # assume 'object' type if missing but 'properties' are defined
      schema['type'] = 'object' if schema['type'].blank? && schema.has_key?('properties')

      # assume 'array' type if missing but 'properties' are defined
      schema['type'] = 'array' if schema['type'].blank? && schema.has_key?('items')

      # default to string
      schema['type'] = 'string' if schema['type'].blank?

      # fix some type names
      schema['type'] = 'boolean' if schema['type'] == 'bool'

      schema['type'].downcase
    end,

    openapi_v3_schema_field: lambda do |connection, schema, is_input|
      if schema.has_key?('allOf')
        field = call(
          'openapi_v3_schema_field_all_of_composition',
          connection,
          schema['allOf'],
          is_input
        )
        field_hint = call(
          'convert_common_mark_to_field_hint_format',
          connection,
          schema['description'],
          nil
        )
        unless field_hint.blank?
          field[:hint] = if field[:hint].blank?
                           field_hint
                         elsif field_hint[-1, 1] == '.'
                           "#{field_hint} #{field[:hint]}"
                         else
                           "#{field_hint}. #{field[:hint]}"
                         end
        end
        field
      elsif schema.has_key?('oneOf')
        call(
          'openapi_v3_schema_field_one_of_composition',
          connection,
          schema,
          is_input
        )
      elsif schema.has_key?('anyOf')
        call(
          'openapi_v3_schema_field_any_of_composition',
          connection,
          schema['anyOf'],
          is_input
        )
      else
        call(
          'openapi_v3_schema_field_no_composition',
          connection,
          schema,
          is_input
        )
      end
    end,

    openapi_v3_schema_field_one_of_composition: lambda do |connection, schemas, is_input|
      schema_items = schemas['oneOf']
      type = ['object']
      properties = []
      if schema_items.find { |s| s['type'] == 'object' } || is_input
        nested_schema = call('merge_schema_objects', schema_items)
        call('openapi_v3_schema_field', connection, nested_schema, is_input)
      else
        schema_items.each do |schema|
          field_type = schema['type'].presence || 'string'
          next if type.include?(schema['type'])

          type << field_type
          properties << {
            name: "___#{field_type}___",
            label: "#{schemas[:__key__]} (#{field_type})".labelize
          }.merge(call('openapi_v3_schema_field', connection, schema, is_input))
        end
        {
          type: 'object',
          properties: properties
        }
      end
    end,

    openapi_v3_schema_field_any_of_composition: lambda do |connection, schema_items, is_input|
      schema = call('merge_schema_objects', schema_items)
      call('openapi_v3_schema_field', connection, schema, is_input)
    end,

    merge_schema_objects: lambda do |schema_items|
      merged_schema = {}
      schema_items&.each do |schema|
        if schema.has_key?('allOf')
          schema = schema.deep_merge(
            call('merge_schema_objects', schema['allOf'])
          )
          schema.delete('allOf')
        elsif schema.has_key?('oneOf')
          schema = schema.deep_merge(
            call('merge_schema_objects', schema['oneOf'])
          )
          schema.delete('oneOf')
        elsif schema.has_key?('anyOf')
          schema = schema.deep_merge(
            call('merge_schema_objects', schema['anyOf'])
          )
          schema.delete('anyOf')
        end
        merged_schema = merged_schema.deep_merge(schema)
      end
      merged_schema
    end,

    openapi_v3_schema_field_all_of_composition: lambda do |connection, schema_items, is_input|
      schema = call('merge_schema_objects', schema_items)
      call('openapi_v3_schema_field', connection, schema, is_input)
    end,

    openapi_v3_schema_field_no_composition: lambda do |connection, schema, is_input|
      call('fix_schema_type', schema)

      field_default = schema['default']

      case schema['type']
      when 'boolean'
        field_type = 'boolean'
        control_type = 'checkbox'
        render_input = 'boolean_conversion'
        parse_output = 'boolean_conversion'
      when 'string'
        case schema['format']
        when 'binary'
          field_type = 'object'
          property_fields = [
            {
              name: 'binary',
              label: 'Binary data',
              type: 'string',
              control_type: 'text',
              default: field_default,
              sticky: true
            },
            {
              name: 'mime_type',
              type: 'string',
              control_type: 'text',
              sticky: true
            },
            {
              name: 'name',
              type: 'string',
              control_type: 'text',
              sticky: true
            }
          ]
          field_default = nil
        else
          field_type = 'string'
          control_type = 'text'
        end
      when 'integer'
        field_type = 'integer'
        control_type = 'integer'
        render_input = 'integer_conversion'
        parse_output = 'integer_conversion'
      when 'number'
        field_type = 'number'
        control_type = 'number'
        render_input = 'float_conversion'
        parse_output = 'float_conversion'
      when 'object'
        field_type = 'object'
        required_properties = schema['required'] || []
        property_fields = schema['properties']&.map do |property_name, property_schema|
          property_field = call('openapi_v3_schema_field', connection,
                                property_schema.merge(__key__: property_name), is_input)
          property_field = property_field&.merge(
            {
              name: property_name,
              optional: !required_properties.include?(property_name)
            }
          )
          unless property_field[:force_optional].nil?
            property_field[:optional] = property_field[:force_optional]
          end
          property_field
        end
        additional_properties = schema['additionalProperties']
        additional_properties = true if additional_properties.nil?
        additional_properties = { 'type' => 'string' } if additional_properties == true
        if (property_fields.nil? || property_fields&.empty?) && additional_properties != false
          field_type = 'array'
          array_items_type = 'object'
          list_mode = 'static'
          force_optional = true
          if additional_properties.is_a?(Hash)
            value_field = call(
              'openapi_v3_schema_field',
              connection,
              additional_properties,
              is_input
            )
          end
          property_fields = [
            {
              name: 'key',
              label: 'Name',
              sticky: true,
              optional: false,
              type: 'string'
            },
            (value_field || {}).merge(
              {
                name: 'value',
                label: 'Value',
                sticky: true,
                optional: false
              }
            )
          ]
        end
      when 'array'
        field_type = 'array'
        if schema.has_key?('items')
          items_field = call('openapi_v3_schema_field', connection,
                             schema['items'], is_input)
          if is_input &&
             items_field[:type] == 'string' &&
             items_field[:pick_list].present?
            field_type = 'string'
            control_type = 'multiselect'
            delimiter = ','
            pick_list = items_field[:pick_list]
          else
            array_items_type = items_field[:type]
            property_fields = items_field[:properties]
          end
        end
      else
        unless schema['type'].nil?
          field_type = 'string'
          control_type = 'text'
          note = 'Using a simple text field due to unexpected type ' \
                 "in schema definition (#{schema['type']})."
        end
      end

      if schema.has_key?('enum')
        pick_list = schema['enum'].map do |value|
          label = if value.is_a? String
                    call('labelize', value)
                  else
                    value
                  end
          [label, value]
        end
        control_type = 'select'
      end

      # format field hint based on description and example value
      field_hint = call(
        'convert_common_mark_to_field_hint_format',
        connection,
        schema['description'],
        nil
      )
      example_value = schema['example']
      if example_value.present? &&
         control_type != 'multiselect' &&
         control_type != 'select'
        field_hint = if field_hint.blank?
                       'E.g.'
                     elsif field_hint.ends_with?('.')
                       "#{field_hint} E.g."
                     else
                       "#{field_hint}, e.g."
                     end
        field_hint = "#{field_hint} #{example_value}"
      end
      unless note.nil?
        field_hint = if field_hint.blank?
                       ''
                     elsif field_hint.ends_with?('.')
                       "#{field_hint}<br><br>"
                     end
        field_hint = "#{field_hint}NOTE: #{note}"
      end

      # TODO: check for 'title' field
      {
        type: field_type,
        sticky: true,
        control_type: control_type,
        hint: field_hint,
        default: field_default,
        properties: property_fields,
        of: array_items_type,
        list_mode: list_mode,
        pick_list: pick_list,
        render_input: render_input,
        parse_output: parse_output,
        force_optional: force_optional,
        delimiter: delimiter
      }.compact
    end,

    sample_action_output: lambda do |connection, input, verb|
      endpoint = call('get_endpoint', connection, input, verb)
      if endpoint.present?
        operation_schema = endpoint['schema']
        expected_response_name = endpoint['expected_response_name']
        openapi_version = endpoint['openapi_version']
        response_media_type = endpoint['response_media_type']
      end
      unless expected_response_name.blank?
        response_object = operation_schema.dig('responses', expected_response_name)
      end
      if response_object.present?
        prefix = call('get_openapi_version_method_prefix', openapi_version)
        sample_output = call(
          "#{prefix}operation_response_sample_output",
          response_object,
          response_media_type
        )
      end
      if sample_output.is_a?(Hash)
        sample_output
      elsif sample_output&.present?
        { result: sample_output }
      end
    end,

    openapi_v2_operation_response_sample_output: lambda do |response,
                                                            _response_media_type|
      example = response['examples']
      unless example.present?
        example = call(
          'openapi_v2_definition_field_sample_output',
          response['schema']
        )
      end
      example
    end,

    openapi_v2_definition_field_sample_output: lambda do |schema|
      example = schema['example']
      if example.nil?
        case schema['type']&.to_s&.downcase
        when 'object'
          example = {}
          if schema.has_key?('properties')
            schema['properties'].each do |property_name, property_schema|
              example[property_name] = call(
                'openapi_v2_definition_field_sample_output',
                property_schema
              )
            end
          end
        when 'array'
          example = [call(
            'openapi_v2_definition_field_sample_output',
            schema['items']
          )]
        end
      end
      example = schema['enum'].first if example.nil? && schema.has_key?('enum')
      example
    end,

    openapi_v3_operation_response_sample_output: lambda do |response,
                                                            response_media_type|
      # get example from media type
      media_type = response.dig('content', response_media_type)
      call('openapi_v3_media_type_object_example_value', media_type)
    end,

    openapi_v3_media_type_object_example_value: lambda do |media_type|
      # get example value
      example_value = media_type['example']
      if example_value.nil? && media_type['examples']&.present?
        example_value = call(
          'openapi_v3_example_object_map_value',
          media_type['examples']
        )
      end
      if example_value.nil? && media_type.has_key?('schema')
        example_value = call('openapi_v3_schema_object_example_value',
                             media_type['schema'])
      end
      example_value
    end,

    openapi_v3_example_object_map_value: lambda do |examples_map|
      examples_values = examples_map.values
      value = examples_values&.find do |example_object|
        example_object['value'].present?
      end&.dig('value')
      if value.blank?
        external_value_url = examples_values&.find do |example_object|
          example_object['externalValue'].present?
        end&.dig('externalValue')
        if external_value_url.present?
          value = get(external_value_url).
                  response_format_raw.
                  to_s
        end
      end
      value
    end,

    openapi_v3_schema_object_example_value: lambda do |schema_object|
      value = if schema_object.has_key?('allOf')
                call('openapi_v3_schema_object_example_value_all_of_composition',
                     schema_object['allOf'])
              elsif schema_object.has_key?('oneOf')
                call('openapi_v3_schema_object_example_value_oneof_of_composition',
                     schema_object['oneOf'])
              elsif schema_object.has_key?('anyOf')
                call('openapi_v3_schema_object_example_value_any_of_composition',
                     schema_object['anyOf'])
              else
                call('openapi_v3_schema_object_example_value_no_composition',
                     schema_object)
              end

      value
    end,

    openapi_v3_schema_object_example_value_all_of_composition: lambda do |schema_items|
      # merge items
      schema = call(
        'merge_schema_objects',
        schema_items
      )
      # get example value
      call('openapi_v3_schema_object_example_value', schema)
    end,

    openapi_v3_schema_object_example_value_oneof_of_composition: lambda do |schema_items|
      fields = schema_items.map do |schema|
        call('openapi_v3_schema_object_example_value', schema)
      end
      fields.first
    end,

    openapi_v3_schema_object_example_value_any_of_composition: lambda do |schema_items|
      fields = schema_items.map do |schema|
        call('openapi_v3_schema_object_example_value', schema)
      end
      fields.first
    end,

    openapi_v3_schema_object_example_value_no_composition: lambda do |schema|
      call('fix_schema_type', schema)

      example_value = schema['example']
      example_value = schema['default'] if example_value.nil?
      if example_value.nil?
        case schema['type']
        when 'boolean'
          example_value = false
        when 'object'
          if schema.has_key?('properties')
            example_value = {}
            schema['properties'].map do |property_name, property_schema|
              example_value[property_name] = call(
                'openapi_v3_schema_object_example_value',
                property_schema
              )
            end
            example_value = example_value.compact
          end
        when 'array'
          if schema.has_key?('items')
            example_value = [call(
              'openapi_v3_schema_object_example_value',
              schema['items']
            )]
            example_value = example_value.compact
          end
        end
        example_value = nil unless example_value.present?
      end
      example_value = schema['enum'].first if example_value.nil? && schema.has_key?('enum')
      example_value
    end,

    openapi_v2_request_parameter_value: lambda do |parameter, input|
      name = parameter['name']
      if parameter['in'] == 'body' && !input.has_key?(name)
        value = {}
        input.each do |k, v|
          prefix = "#{name}_"
          if k.starts_with?(prefix)
            sub_key = k.last(k.length - prefix.length)
            value[sub_key] = v
          end
        end
        value
      else
        input[name]
      end
    end,

    openapi_v2_schema_field: lambda do |connection, schema, is_input|
      # handle composition and inheritance (Polymorphism)
      if schema.has_key?('allOf')
        all_of_result = call(
          'merge_schema_objects',
          schema['allOf']
        )
        schema = all_of_result.merge(schema)
      end
      if schema.has_key?('oneOf')
        one_of_result = call(
          'merge_schema_objects',
          schema['oneOf']
        )
        schema = one_of_result.merge(schema)
      end

      call('fix_schema_type', schema)

      case schema['type']
      when 'boolean'
        field_type = 'boolean'
        control_type = 'checkbox'
        render_input = 'boolean_conversion'
        parse_output = 'boolean_conversion'
      when 'string'
        field_type = 'string'
        control_type = 'text'
      when 'integer'
        field_type = 'integer'
        control_type = 'integer'
        render_input = 'integer_conversion'
        parse_output = 'integer_conversion'
      when 'number'
        field_type = 'number'
        control_type = 'number'
        render_input = 'float_conversion'
        parse_output = 'float_conversion'
      when 'object'
        field_type = 'object'
        if schema.has_key?('properties')
          property_fields = schema['properties'].map do |property_name, property_schema|
            required_properties = schema['required'] || []
            next if property_schema['readOnly'] && is_input == true

            property_field = call(
              'openapi_v2_schema_field',
              connection,
              property_schema,
              is_input
            ).merge(
              {
                name: property_name,
                optional: !required_properties.include?(property_name)
              }
            )
            unless property_field[:force_optional].nil?
              property_field[:optional] = property_field[:force_optional]
            end
            property_field
          end.compact
        end
        additional_properties = schema['additionalProperties']
        additional_properties = true if additional_properties.nil?
        additional_properties = { 'type' => 'string' } if additional_properties == true
        if (property_fields.nil? || property_fields&.empty?) && additional_properties != false
          field_type = 'array'
          array_items_type = 'object'
          list_mode = 'static'
          force_optional = true
          if additional_properties.is_a?(Hash)
            value_field = call(
              'openapi_v2_schema_field',
              connection,
              additional_properties,
              is_input
            )
          end
          property_fields = [
            {
              name: 'key',
              label: 'Name',
              sticky: true,
              optional: false,
              type: 'string'
            },
            (value_field || {}).merge(
              {
                name: 'value',
                label: 'Value',
                sticky: true,
                optional: false
              }
            )
          ]
        end
      when 'array'
        field_type = 'array'
        items_field = call('openapi_v2_schema_field', connection, schema['items'], is_input)
        if is_input &&
           items_field[:type] == 'string' &&
           items_field[:pick_list].present?
          field_type = 'string'
          control_type = 'multiselect'
          delimiter = ','
          pick_list = items_field[:pick_list]
        else
          array_items_type = items_field[:type]
          property_fields = items_field[:properties]
        end
      else
        unless schema['type'].nil?
          field_type = 'string'
          control_type = 'text'
        end
      end

      if schema.has_key?('enum')
        pick_list = schema['enum'].map { |value| [call('labelize', value), value] }
        control_type = 'select'
      end

      field_hint = call(
        'convert_common_mark_to_field_hint_format',
        connection,
        schema['description'],
        nil
      )

      {
        type: field_type,
        sticky: true,
        control_type: control_type,
        hint: field_hint,
        default: schema['default'],
        properties: property_fields,
        of: array_items_type,
        list_mode: list_mode,
        pick_list: pick_list,
        render_input: render_input,
        parse_output: parse_output,
        force_optional: force_optional,
        delimiter: delimiter
      }.compact
    end,

    parse_yaml: lambda do |content|
      # convert multi-line strings with single-quotes into single-line strings
      content = content.gsub(/(\w+:\s+'[^']*)(\s*\n\s*)/, '\1 ')
      # fix unsupported Date, Time or DateTime values
      content = content.gsub(%r{^(\s*[\w<>.]+): (\d.*[-/:]*.*)$}, '\1: \'\2\'')
      # finally, parse the YAML
      parsed_data = YAML.safe_load(content, permitted_classes: [Date, Time, DateTime, Symbol], aliases: true)
    end,

    fetch_gcs_object: lambda do |connection|
      bucket = connection['gcp_bucket'].strip
      object = connection['gcp_object'].strip
      sa_private_token = connection['sa_private_token']

      sa_json = JSON.parse(sa_private_token)
      client_email = sa_json.fetch("client_email")
      private_key_pem = sa_json.fetch("private_key")
      rsa = OpenSSL::PKey::RSA.new(private_key_pem)

      def b64url(str)
        Base64.urlsafe_encode64(str).delete("=")
      end

      now = Time.now.to_i
      hdr = { alg: "RS256", typ: "JWT" }
      claims = {
        iss: client_email,
        scope: "https://www.googleapis.com/auth/devstorage.read_only",
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600
      }
      header_b64 = b64url(hdr.to_json)
      claims_b64 = b64url(claims.to_json)
      signed_input = "#{header_b64}.#{claims_b64}"
      sig = rsa.sign(OpenSSL::Digest::SHA256.new, signed_input)
      assertion = "#{signed_input}.#{b64url(sig)}"

      # Exchange for an access token
      uri = URI("https://oauth2.googleapis.com/token")
      res = Net::HTTP.post_form(uri, {
        "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion"  => assertion
      })
      abort "Token exchange failed: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)
      access_token = JSON.parse(res.body).fetch("access_token")

      # Download the object (JSON API download endpoint)
      def url_encode_object(path)
        # GCS expects percent-encoding of the full object name in the path segment
        CGI.escape(path).gsub("+", "%20").gsub("%7E", "~")
      end
      enc_obj = url_encode_object(object)
      download_url = URI("https://storage.googleapis.com/download/storage/v1/b/#{bucket}/o/#{enc_obj}?alt=media")

      req = Net::HTTP::Get.new(download_url)
      req["Authorization"] = "Bearer #{access_token}"

      Net::HTTP.start(download_url.host, download_url.port, use_ssl: true) do |http|
        resp = http.request(req)
        raise "download failed: #{resp.code} #{resp.body[0, 200]}" unless resp.is_a?(Net::HTTPSuccess)
        return resp.body  # Return content as String
      end
    end,

    get_api_definition: lambda do |connection|
      unless connection.has_key?('spec')
        content = call('fetch_gcs_object', connection)
        unless content.nil?
          content = content.strip
          # if it's a JSON string, parse it
          if content.starts_with?('"') && content.ends_with?('"')
            content = workato.parse_json(content)
            content = content.strip
          end
          spec = if content.starts_with?('{')
                   workato.parse_json(content)
                 else
                   call('parse_yaml', content)
                 end
        end
        connection['spec'] = spec
      end
      connection['spec']
    end,

    get_openapi_version: lambda do |api_definition|
      version = api_definition['swagger'] || api_definition['openapi']
      error('missing OpenAPI spec version') if version.blank?
      version
    end,

    get_openapi_version_method_prefix: lambda do |version|
      error('OpenAPI version not provided') if version.blank?
      match = version.match(/(?<major>\d+)
                             (?<after_major>\.(?<minor>\d+)
                             (?<after_minor>\.(?<patch>\d+)
                             )?)?/x)
      error("unexpected OpenAPI version format '#{version}'") if match.nil?
      case match['major']
      when '2'
        'openapi_v2_'
      when '3'
        'openapi_v3_'
      else
        error("unsupported OpenAPI version '#{version}'")
      end
    end,

    get_endpoint_tags: lambda do |api_spec|
      tags = {}
      api_spec['tags']&.map do |tag|
        tags[tag['name']] = tag
      end || {}
      paths = api_spec['paths'].values
      operations = paths.map do |path|
        [path['get'], path['post'], path['put'], path['delete'], path['patch']].compact
      end.flatten
      tag_names = operations.map do |operation|
        operation['tags']
      end.compact.flatten.uniq
      tag_names.map do |name|
        {
          name: name,
          description: tags[name]&.[]('description')
        }
      end
    end,

    dig_api_definition: lambda do |api_spec, ref|
      error('dig_api_definition nil ref') if ref.nil?
      ref = ref[2..-1]
      ref = ref.split('/')
      node = api_spec
      ref.each do |name|
        next if node.nil?

        # handle array indexes
        if node.is_a?(Array) &&
           name == name.to_i.to_s &&
           node.length > name.to_i
          node = node[name.to_i]
          next
        end

        # handle hash keys
        if node.is_a?(Hash) &&
           node.has_key?(name)
          node = node[name]
          next
        end

        node = nil
      end
      node
    end,

    get_endpoint: lambda do |connection, input, verb|
      record_json = input["object_for_#{verb}"]
      record = workato.parse_json(record_json) unless record_json.blank?
      operation = record['schema'] if record.present?
      if operation.present?
        default_expected_response_name = call('get_default_expected_response_name', operation, verb)
        request_media_types = call('get_request_media_types', connection, operation)
      end
      user_expected_response_name = input['expected_response_name']
      expected_response_name = if user_expected_response_name.present?
                                 user_expected_response_name
                               elsif default_expected_response_name.present?
                                 default_expected_response_name
                               end
      if expected_response_name.present?
        response_media_types = call(
          'get_response_media_types',
          connection,
          operation,
          expected_response_name
        )
      end
      if record.present?
        record['expected_response_name'] = expected_response_name
        record['request_media_type'] = request_media_types&.first
        record['response_media_type'] = response_media_types&.first
      end
      record&.compact
    end,

    apply_text_substitutions_for_grouping: lambda do |connection, path, operation|
      # get deprecated operation_id substitutions
      deprecated_operation_id_substitution_for_grouping = connection.dig(
        'advanced',
        'operation_id_substitution_for_grouping'
      )
      if deprecated_operation_id_substitution_for_grouping.nil?
        deprecated_operation_id_substitution_for_grouping = connection[
          'operation_id_substitution_for_grouping'
        ]
      end
      # get substitutions
      substitutions = connection.dig(
        'advanced',
        'substitutions_for_grouping'
      ) || []
      # append deprecated substitutions
      if deprecated_operation_id_substitution_for_grouping.present?
        deprecated_operation_id_substitution_for_grouping.each do |s|
          s = s.merge('apply_to' => 'operation_id')
          substitutions << s
        end
      end
      # get initial values
      operation_id = operation['operationId']
      description = operation['description']&.downcase
      summary = operation['summary']&.downcase
      # substitute values
      substitutions.each do |substitution|
        pattern = /#{substitution['pattern']}/
        replacement = substitution['replacement']
        apply_to = substitution['apply_to']
        case apply_to
        when nil, ''
          apply_to_summary = true
          apply_to_operation_id = true
          apply_to_description = true
          apply_to_path = true
        when 'summary'
          apply_to_summary = true
        when 'operation_id'
          apply_to_operation_id = true
        when 'description'
          apply_to_description = true
        when 'path'
          apply_to_path = true
        end
        if apply_to_summary
          new_summary = summary&.gsub(pattern, replacement)
          summary = new_summary unless new_summary.blank?
        end
        if apply_to_operation_id
          new_operation_id = operation_id&.gsub(pattern, replacement)
          operation_id = new_operation_id unless new_operation_id.blank?
        end
        if apply_to_description
          new_description = description&.gsub(pattern, replacement)
          description = new_description unless new_description.blank?
        end
        if apply_to_path
          new_path = path&.gsub(pattern, replacement)
          path = new_path unless new_path.blank?
        end
      end
      # return substituted values
      {
        operation_id: operation_id,
        description: description,
        summary: summary,
        path: path
      }
    end,

    match_operation_fields_with_keywords: lambda do |_connection, operation_fields, verb_keywords|
      operation_id = call('labelize', operation_fields[:operation_id])&.downcase
      description = call('labelize', operation_fields[:description])&.downcase
      summary = call('labelize', operation_fields[:summary])&.downcase
      path = call('labelize', operation_fields[:path])&.downcase

      verb_keywords.find do |keyword|
        description&.starts_with?(keyword) ||
          operation_id&.starts_with?(keyword) ||
          summary&.starts_with?(keyword) ||
          path&.starts_with?(keyword)
      end.present?
    end,

    has_operation_plural_name: lambda do |_connection, operation_fields|
      names = [
        operation_fields[:path],
        operation_fields[:operation_id],
        operation_fields[:summary],
        operation_fields[:description]
      ].compact

      names = names.map do |name|
        name&.downcase&.labelize&.split&.last&.downcase
      end.compact

      names.find do |name|
        name.pluralize.downcase == name
      end.present?
    end,

    get_object_label_from_operation: lambda do |connection, path, verb, operation, verb_keywords|
      operation_id = operation['operationId']
      summary = operation['summary']
      description = operation['description']
      object_label_field = connection.dig('advanced', 'object_label_field')
      object_label_field = connection['object_label_field'] if object_label_field.nil?

      # ignore user-selected field if no value available
      object_label_field = nil if object_label_field == 'operation_id' && operation_id.blank?
      object_label_field = nil if object_label_field == 'summary' && summary.blank?
      object_label_field = nil if object_label_field == 'description' && description.blank?

      object_label_field = 'summary' if !summary.blank? && object_label_field.blank?
      object_label_field = 'operation_id' if !operation_id.blank? && object_label_field.blank?
      object_label_field = 'description' if !description.blank? && object_label_field.blank?
      object_label_substitutions = connection.dig('advanced', 'object_label_substitutions')
      if object_label_substitutions.nil?
        object_label_substitutions = connection['object_label_substitutions']
      end
      case object_label_field
      when 'summary', 'description'
        object_label = summary if object_label_field == 'summary'
        object_label = description if object_label_field == 'description'
        object_label_substitutions&.each do |substitution|
          pattern = /#{substitution['pattern']}/
          replacement = substitution['replacement']
          new_object_label = object_label&.gsub(pattern, replacement)
          object_label = new_object_label unless new_object_label.blank?
        end
        verb_keywords = verb_keywords.map do |keyword|
          [
            "#{keyword} the ",
            "#{keyword} an ",
            "#{keyword} a ",
            keyword
          ]
        end.flatten
      when 'operation_id'
        object_label = operation_id
        object_label_substitutions&.each do |substitution|
          pattern = /#{substitution['pattern']}/
          replacement = substitution['replacement']
          new_object_label = object_label.gsub(pattern, replacement)
          object_label = new_object_label unless new_object_label.blank?
        end
        object_label = call('labelize', object_label)
      end
      unless object_label.blank?
        object_label = call('labelize', object_label)
        verb_keywords.each do |keyword|
          if object_label.downcase.starts_with?(keyword)
            object_label = object_label[keyword.length..-1]
            object_label = object_label.strip
          end
        end
        %w[\ objects \ object .].each do |suffix|
          if object_label.ends_with? suffix
            object_label = object_label[0...(object_label.length - suffix.length)]
          end
        end
      end
      object_label = path if object_label.blank?
      object_label = call('labelize', object_label)
      object_label = object_label&.singularize if verb != 'search'
      object_label_map = call('get_object_label_map', connection)
      object_label = object_label_map[operation_id] if object_label_map&.has_key?(operation_id)
      object_label
    end,

    get_operation_label_from_operation: lambda do |connection, path, operation|
      operation_id = operation['operationId']
      summary = operation['summary']
      description = operation['description']
      label_field = connection.dig('advanced', 'execute_operation_label_field')
      label_field = connection['execute_operation_label_field'] if label_field.nil?
      label_field = connection.dig('advanced', 'object_label_field') if label_field.nil?
      label_field = connection['object_label_field'] if label_field.nil?

      # ignore user-selected field if no value available
      label_field = nil if label_field == 'operation_id' && operation_id.blank?
      label_field = nil if label_field == 'summary' && summary.blank?
      label_field = nil if label_field == 'description' && description.blank?

      label_field = 'summary' if !summary.blank? && label_field.blank?
      label_field = 'operation_id' if !operation_id.blank? && label_field.blank?
      label_field = 'description' if !description.blank? && label_field.blank?
      case label_field
      when 'summary'
        object_label = summary
      when 'operation_id'
        object_label = operation_id
      when 'description'
        object_label = description
      end
      object_label = path if object_label.blank?
      object_label = call('labelize', object_label)
      object_label_map = call('get_object_label_map', connection)
      object_label = object_label_map[operation_id] if object_label_map&.has_key?(operation_id)
      object_label
    end,

    generate_component_schema_interitance_map: lambda do |_connection, api_definition|
      map = {}
      api_definition.dig('components', 'schemas')&.each do |schema_name, schema|
        next unless schema['allOf'].present? &&
                    schema['allOf'].length == 1

        ref = schema['allOf'].first['$ref']
        next unless ref.present?

        map[ref] = [] if map[ref].blank?
        map[ref] << "#/components/schemas/#{schema_name}"
      end
      map
    end,

    dereference_object: lambda do |_connection, _state, api_definition, object|
      if object&.has_key? '$ref'
        ref = object['$ref']
        referenced_object = call('dig_api_definition', api_definition, ref)
        if referenced_object.nil?
          puts "Could not find object '#{ref}'"
          object
        else
          referenced_object
        end
      else
        object
      end
    end,

    dereference_path_item: lambda do |connection, api_definition,
                                      inheritance_map, path_item|
      openapi_version = call('get_openapi_version', api_definition)
      method_prefix = call('get_openapi_version_method_prefix', openapi_version)
      call(
        "#{method_prefix}dereference_path_item",
        connection,
        {},
        api_definition,
        inheritance_map,
        path_item
      )
    end,

    openapi_v2_dereference_path_item: lambda do |connection,
                                                 state,
                                                 api_definition,
                                                 _inheritance_map,
                                                 path_item|
      path_item = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        path_item
      )
      path_item_updates = {}
      %w[get put post delete patch].each do |op_name|
        operation_object = path_item[op_name]
        next if operation_object.nil?

        operation_object['parameters'] ||= []
        operation_object['parameters'].concat(path_item['parameters'] || [])
        path_item_updates[op_name] = call(
          'openapi_v2_dereference_operation_object',
          connection,
          state,
          api_definition,
          path_item,
          operation_object
        )
      end
      path_item.merge(path_item_updates)
    end,

    openapi_v2_dereference_operation_object: lambda do |connection,
                                                        state,
                                                        api_definition,
                                                        _path_item,
                                                        operation_object|
      operation_object_updates = {}
      operation_object_updates['parameters'] = operation_object['parameters']&.
        map do |parameter_object|
          call(
            'openapi_v2_dereference_parameter_object',
            connection,
            state,
            api_definition,
            parameter_object
          )
        end
      unless operation_object['responses'].nil?
        operation_object_updates['responses'] = call(
          'openapi_v2_dereference_responses_object',
          connection,
          state,
          api_definition,
          operation_object['responses']
        )
      end
      operation_object.merge(operation_object_updates).compact
    end,

    openapi_v2_dereference_parameter_object: lambda do |connection,
                                                        state,
                                                        api_definition,
                                                        parameter_object|
      parameter_object = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        parameter_object
      )
      parameter_object_updates = {}
      unless parameter_object['schema'].nil?
        parameter_object_updates['schema'] = call(
          'openapi_v2_dereference_schema_object',
          connection,
          state,
          api_definition,
          parameter_object['schema']
        )
      end
      if parameter_object.has_key? 'items'
        parameter_object_updates['items'] = call(
          'openapi_v2_dereference_schema_object',
          connection,
          state,
          api_definition,
          parameter_object['items']
        )
      end
      parameter_object.merge(parameter_object_updates).compact
    end,

    openapi_v2_dereference_responses_object: lambda do |connection, state,
                                                        api_definition,
                                                        responses_object|
      responses_object = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        responses_object
      )
      responses = {}
      %w[default 200 201 202 204 default].each do |response_name|
        response_object = responses_object[response_name]
        next if response_object.nil?

        responses[response_name] = call(
          'openapi_v2_dereference_response_object',
          connection,
          state,
          api_definition,
          response_object
        )
      end
      responses_object.merge(responses).compact
    end,

    openapi_v2_dereference_response_object: lambda do |connection, state,
                                                       api_definition,
                                                       response_object|
      response_object = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        response_object
      )

      response_object_updates = {}
      unless response_object['schema'].nil?
        response_object_updates['schema'] = call(
          'openapi_v2_dereference_schema_object',
          connection,
          state,
          api_definition,
          response_object['schema']
        )
      end
      response_object.merge(response_object_updates).compact
    end,

    openapi_v2_dereference_schema_object: lambda do |connection,
                                                     state,
                                                     api_definition,
                                                     schema_object|
      expand = true
      schema_object = {} unless schema_object.is_a? Hash
      ref = schema_object['$ref']
      unless ref.nil?
        ref_count = state[ref] || 0
        state[ref] = ref_count + 1
        max_recursion_depth = call('get_max_recursion_depth', connection)
        expand = false if expand && ref_count >= max_recursion_depth
      end
      depth = state['_'] || 0
      state['_'] = depth + 1
      max_schema_depth = call('get_max_schema_depth', connection)
      expand = false if expand && depth >= max_schema_depth

      schema_object = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        schema_object
      )

      schema_object_updates = {}
      if expand
        schema_object_updates['allOf'] = schema_object['allOf']&.map do |item|
          call(
            'openapi_v2_dereference_schema_object',
            connection,
            state,
            api_definition,
            item
          )
        end
        if schema_object.has_key? 'items'
          schema_object_updates['items'] = call(
            'openapi_v2_dereference_schema_object',
            connection,
            state,
            api_definition,
            schema_object['items']
          )
        end
        properties = {}
        schema_object['properties']&.each do |name, object|
          next if object.nil?

          properties[name] = call(
            'openapi_v2_dereference_schema_object',
            connection,
            state,
            api_definition,
            object
          )
        end
        schema_object_updates['properties'] = properties if properties.present?
        if schema_object['additionalProperties'].is_a?(Hash)
          schema_object_updates['additionalProperties'] = call(
            'openapi_v2_dereference_schema_object',
            connection,
            state,
            api_definition,
            schema_object['additionalProperties']
          )
        end
      else
        schema_object_updates['allOf'] = nil
        schema_object_updates['oneOf'] = nil
        schema_object_updates['anyOf'] = nil
        schema_object_updates['items'] = nil
        schema_object_updates['properties'] = nil
        schema_object_updates['additionalProperties'] = false
      end

      state[ref] = ref_count unless ref.nil?
      state['_'] = depth

      schema_object.merge(schema_object_updates).compact
    end,

    openapi_v2_get_output_value: lambda do |schema, value_from_response|
      call('fix_schema_type', schema)

      case schema['type']
      when 'object'
        if value_from_response.is_a?(Hash)
          property_fields = schema['properties']
          additional_properties = schema['additionalProperties']
          additional_properties = true if additional_properties.nil?
          additional_properties = { 'type' => 'string' } if additional_properties == true
          is_key_value_list = (property_fields.nil? || property_fields&.empty?) &&
                              additional_properties != false
          if is_key_value_list
            list = []
            value_from_response.each do |property_name, property_value|
              property_value = call(
                'openapi_v2_get_output_value',
                additional_properties,
                property_value
              )
              list.push({ 'key' => property_name, 'value' => property_value })
            end
            list
          else
            object = {}
            property_fields = property_fields&.select do |property_name, _property_schema|
              value_from_response.has_key?(property_name)
            end
            property_fields&.each do |property_name, property_schema|
              property_value = value_from_response[property_name]
              property_value = call(
                'openapi_v2_get_output_value',
                property_schema,
                property_value
              )
              object[property_name] = property_value
            end
            object
          end
        else
          value_from_response
        end
      when 'array'
        if schema.has_key?('items')
          value_from_response&.map do |item|
            call(
              'openapi_v2_get_output_value',
              schema['items'],
              item
            )
          end
        else
          value_from_response
        end
      else
        value_from_response
      end
    end,

    openapi_v3_dereference_path_item: lambda do |connection,
                                                 state,
                                                 api_definition,
                                                 inheritance_map,
                                                 path_item|
      path_item = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        path_item
      )
      path_item_updates = {}
      %w[get put post delete patch].each do |op_name|
        operation_object = path_item[op_name]
        next if operation_object.nil?

        operation_object = operation_object.merge(
          path_item.slice('parameters')
        )
        path_item_updates[op_name] = call(
          'openapi_v3_dereference_operation_object',
          connection,
          state,
          api_definition,
          inheritance_map,
          path_item,
          operation_object
        )
      end
      path_item.merge(path_item_updates)
    end,

    openapi_v3_dereference_operation_object: lambda do |connection,
                                                        state,
                                                        api_definition,
                                                        inheritance_map,
                                                        _path_item,
                                                        operation_object|
      operation_object_updates = {}
      operation_object_updates['parameters'] = operation_object['parameters']&.
        map do |parameter_object|
          call(
            'openapi_v3_dereference_parameter_object',
            connection,
            state,
            api_definition,
            inheritance_map,
            parameter_object
          )
        end
      unless operation_object['requestBody'].nil?
        operation_object_updates['requestBody'] = call(
          'openapi_v3_dereference_request_body_object',
          connection,
          state,
          api_definition,
          inheritance_map,
          operation_object['requestBody']
        )
      end
      unless operation_object['responses'].nil?
        operation_object_updates['responses'] = call(
          'openapi_v3_dereference_responses_object',
          connection,
          state,
          api_definition,
          inheritance_map,
          operation_object['responses']
        )
      end
      # TODO: callbacks
      operation_object.merge(operation_object_updates).compact
    end,

    openapi_v3_dereference_parameter_object: lambda do |connection, state,
                                                        api_definition,
                                                        inheritance_map,
                                                        parameter_object|
      parameter_object = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        parameter_object
      )
      parameter_object_updates = {}
      unless parameter_object['schema'].nil?
        parameter_object_updates['schema'] = call(
          'openapi_v3_dereference_schema_object',
          connection,
          state,
          api_definition,
          inheritance_map,
          false,
          parameter_object['schema']
        )
      end
      examples = {}
      parameter_object['examples']&.map do |name, object|
        examples[name] = call(
          'openapi_v3_dereference_example_object',
          connection,
          state,
          api_definition,
          inheritance_map,
          object
        )
      end
      parameter_object_updates['examples'] = examples if examples.present?
      parameter_object.merge(parameter_object_updates).compact
    end,

    openapi_v3_dereference_example_object: lambda do |connection,
                                                      state,
                                                      api_definition,
                                                      _inheritance_map,
                                                      example_object|
      call(
        'dereference_object',
        connection,
        state,
        api_definition,
        example_object
      )
    end,

    openapi_v3_dereference_schema_object: lambda do |connection,
                                                     state,
                                                     api_definition,
                                                     inheritance_map,
                                                     prevent_inheritance_expansion,
                                                     schema_object|
      expand = true
      # a schema object has to be of type Hash
      # if it is not, ignore it completely
      schema_object = {} unless schema_object.is_a? Hash
      ref = schema_object['$ref']
      unless ref.nil?
        ref_count = state[ref] || 0
        state[ref] = ref_count + 1
        max_recursion_depth = call('get_max_recursion_depth', connection)
        expand = false if expand && ref_count >= max_recursion_depth
      end
      depth = state['_'] || 0
      state['_'] = depth + 1
      max_schema_depth = call('get_max_schema_depth', connection)
      expand = false if expand && depth >= max_schema_depth

      # handle inheritance by replacing super-reference by sub-reference list
      if schema_object&.has_key?('$ref') && !prevent_inheritance_expansion
        ref = schema_object['$ref']
        if inheritance_map[ref].present?
          schema_object = schema_object.merge({})
          schema_object.delete('$ref')
          unless schema_object.present?
            schema_object = {
              'oneOf' => inheritance_map[ref].map do |child_schema|
                { '$ref' => child_schema }
              end
            }
          end
        end
      end

      schema_object = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        schema_object
      )
      schema_object_updates = {}
      if expand
        schema_object_updates['allOf'] = schema_object['allOf']&.map do |item|
          call(
            'openapi_v3_dereference_schema_object',
            connection,
            state,
            api_definition,
            inheritance_map,
            true,
            item
          )
        end
        schema_object_updates['oneOf'] = schema_object['oneOf']&.map do |item|
          call(
            'openapi_v3_dereference_schema_object',
            connection,
            state,
            api_definition,
            inheritance_map,
            true,
            item
          )
        end
        schema_object_updates['anyOf'] = schema_object['anyOf']&.map do |item|
          call(
            'openapi_v3_dereference_schema_object',
            connection,
            state,
            api_definition,
            inheritance_map,
            true,
            item
          )
        end
        if schema_object.has_key? 'items'
          schema_object_updates['items'] = call(
            'openapi_v3_dereference_schema_object',
            connection,
            state,
            api_definition,
            inheritance_map,
            false,
            schema_object['items']
          )
        end
        properties = {}
        schema_object['properties']&.each do |name, object|
          next if object.nil?

          properties[name] = call(
            'openapi_v3_dereference_schema_object',
            connection,
            state,
            api_definition,
            inheritance_map,
            false,
            object
          )
        end
        schema_object_updates['properties'] = properties if properties.present?
        if schema_object['additionalProperties'].is_a?(Hash)
          schema_object_updates['additionalProperties'] = call(
            'openapi_v3_dereference_schema_object',
            connection,
            state,
            api_definition,
            inheritance_map,
            false,
            schema_object['additionalProperties']
          )
        end
      else
        schema_object_updates['allOf'] = nil
        schema_object_updates['oneOf'] = nil
        schema_object_updates['anyOf'] = nil
        schema_object_updates['items'] = nil
        schema_object_updates['properties'] = nil
        schema_object_updates['additionalProperties'] = false
      end
      state[ref] = ref_count unless ref.nil?
      state['_'] = depth
      schema_object.merge(schema_object_updates).compact
    end,

    openapi_v3_dereference_request_body_object: lambda do |connection, state,
                                                           api_definition,
                                                           inheritance_map,
                                                           request_body|
      request_body = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        request_body
      )
      request_body_updates = {}
      content = {}
      request_body['content']&.map do |name, media_type_object|
        content[name] = call(
          'openapi_v3_dereference_media_type_object',
          connection,
          state,
          api_definition,
          inheritance_map,
          media_type_object
        )
      end
      request_body_updates['content'] = content if content.present?
      request_body.merge(request_body_updates).compact
    end,

    openapi_v3_dereference_media_type_object: lambda do |connection, state,
                                                         api_definition,
                                                         inheritance_map,
                                                         media_type_object|
      media_type_object = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        media_type_object
      )
      media_type_object_updates = {}
      unless media_type_object['schema'].nil?
        media_type_object_updates['schema'] = call(
          'openapi_v3_dereference_schema_object',
          connection,
          state,
          api_definition,
          inheritance_map,
          false,
          media_type_object['schema']
        )
      end
      examples = {}
      media_type_object['examples']&.map do |name, example_object|
        examples[name] = call(
          'dereference_object',
          connection,
          state,
          api_definition,
          example_object
        )
      end
      media_type_object_updates['examples'] = examples if examples.present?
      # TODO: encoding
      media_type_object.merge(media_type_object_updates).compact
    end,

    openapi_v3_dereference_responses_object: lambda do |connection, state,
                                                        api_definition,
                                                        inheritance_map,
                                                        responses_object|
      responses_object = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        responses_object
      )
      responses = {}
      %w[default 200 201 202 204].each do |response_name|
        response_object = responses_object[response_name]
        if response_name != 'default' && response_object.nil?
          response_object = responses_object[response_name.to_i]
        end
        next if response_object.nil?

        responses[response_name] = call(
          'openapi_v3_dereference_response_object',
          connection,
          state,
          api_definition,
          inheritance_map,
          response_object
        )
      end
      responses_object.merge(responses)
    end,

    openapi_v3_dereference_response_object: lambda do |connection,
                                                       state,
                                                       api_definition,
                                                       inheritance_map,
                                                       response_object|
      response_object = call(
        'dereference_object',
        connection,
        state,
        api_definition,
        response_object
      )

      response_object_updates = {}
      content = {}
      response_object['content']&.map do |name, media_type_object|
        content[name] = call(
          'openapi_v3_dereference_media_type_object',
          connection,
          state,
          api_definition,
          inheritance_map,
          media_type_object
        )
      end
      response_object_updates['content'] = content if content.present?
      response_object.merge(response_object_updates).compact
    end,

    get_search_operation_response_list_fields: lambda do |_connection, response_fields|
      array_fields = response_fields.select do |field|
        field[:type] == 'array'
      end
      array_fields
    end,

    is_search_operation: lambda do |connection, keyword_map, path, endpoint, substituted_fields|
      record_id_field_name = connection.dig('advanced', 'record_id_field_name')
      record_id_field_name = connection['record_id_field_name'] if record_id_field_name.nil?
      path_has_id_placeholder_at_the_end_re = if record_id_field_name.blank?
                                                /[iI][dD]}$/
                                              else
                                                /#{record_id_field_name}}$/i
                                              end
      last_path_component = substituted_fields[:path].downcase.labelize.split.last.downcase
      looks_like_returning_a_list = (
        (
          call('match_operation_fields_with_keywords',
               connection,
               substituted_fields,
               keyword_map['search']) ||
          (
            call('match_operation_fields_with_keywords',
                 connection,
                 substituted_fields,
                 keyword_map['get']) &&
            (
              call('has_operation_plural_name', connection, substituted_fields) ||
              last_path_component.ends_with?('list')
            ) &&
            !last_path_component.ends_with?('details') &&
            !last_path_component.ends_with?('status') &&
            !last_path_component.ends_with?('stats')
          )
        ) &&
        !path.match?(path_has_id_placeholder_at_the_end_re)
      )

      if looks_like_returning_a_list
        response_fields = call(
          'response_fields',
          connection,
          'search',
          endpoint
        )
        if response_fields.present?
          actually_returns_a_list = call(
            'get_search_operation_response_list_fields',
            connection,
            response_fields
          ).present?
        end
      end
      looks_like_returning_a_list && actually_returns_a_list
    end,

    get_record_identifier_fields: lambda do |_connection, record_fields|
      identifier_fields = record_fields&.select do |field|
        name = field[:name].downcase
        %w[string integer].include?(field[:type]) &&
          %w[id identifier].include?(name)
      end
      if identifier_fields.empty?
        identifier_fields = record_fields&.select do |field|
          name = field[:name].downcase
          %w[string integer].include?(field[:type]) &&
            (
              name.ends_with?('id') ||
              name.ends_with?('name')
            )
        end
      end
      identifier_fields
    end,

    get_record_timestamp_fields: lambda do |_connection, record_fields|
      record_fields&.select do |field|
        name = field[:name].downcase
        %w[date_time timestamp date].include?(field[:type]) ||
          (
            %w[string integer].include?(field[:type]) &&
            (
              name.include?('update') ||
              name.include?('change') ||
              name.include?('create') ||
              name.include?('modify') ||
              name.include?('modified') ||
              (name.include?('time') && !name.include?('zone')) ||
              name.include?('stamp')
            )
          )
      end
    end,

    get_timestamp_request_fields: lambda do |_connection, request_fields|
      is_primary = lambda do |field|
        name = field[:name].downcase
        %w[date_time timestamp date string integer].include?(field[:type]) &&
          (
            name.include?('update') ||
            name.include?('change') ||
            name.include?('modify') ||
            name.include?('modified') ||
            (name.include?('time') && !name.include?('zone')) ||
            name.include?('stamp')
          ) &&
          (
            name.include?('since') ||
            name.include?('later') ||
            name.include?('gte') ||
            name.include?('gt') ||
            name.include?('after')
          )
      end
      is_secondary = lambda do |field|
        name = field[:name].downcase
        hint = field[:hint]&.downcase
        is_possible_timestamp_field = false
        unless is_possible_timestamp_field == true
          timestamp_types = %w[date_time timestamp date]
          is_possible_timestamp_field = timestamp_types.include?(field[:type])
        end
        unless is_possible_timestamp_field == true
          is_possible_timestamp_field = %w[string integer].include?(field[:type]) &&
                                        (
                                          name.include?('update') ||
                                          name.include?('change') ||
                                          name.include?('create') ||
                                          name.include?('modify') ||
                                          name.include?('modified') ||
                                          (name.include?('time') && !name.include?('zone')) ||
                                          name.include?('stamp') ||
                                          name.include?('since') ||
                                          name.include?('start') ||
                                          name.include?('after')
                                        )
        end
        if !is_possible_timestamp_field && hint.present?
          is_possible_timestamp_field = %w[string integer].include?(field[:type]) &&
                                        hint.include?('yy-mm-dd')
        end
        is_possible_timestamp_field
      end
      filter_fields = lambda do |match_field|
        request_fields&.select do |field|
          match_field.call(field)
        end
      end
      filtered = filter_fields.call(is_primary)
      filtered = filter_fields.call(is_secondary) unless filtered.present?
      filtered
    end,

    get_cursor_pagination_response_fields: lambda do |_connection, response_fields|
      response_fields&.select do |field|
        field[:type] == 'string' &&
          (
            field[:name].downcase.include?('token') ||
            field[:name].downcase.include?('from') ||
            field[:name].downcase.include?('next') ||
            field[:name].downcase.include?('cursor')
          )
      end
    end,

    get_cursor_pagination_request_fields: lambda do |_connection, request_fields|
      request_fields&.select do |field|
        field[:type] == 'string' &&
          (
            field[:name].downcase.include?('token') ||
            field[:name].downcase.include?('next') ||
            field[:name].downcase.include?('cursor')
          )
      end
    end,

    get_next_link_pagination_response_fields: lambda do |_connection, response_fields|
      response_fields&.select do |field|
        field[:type] == 'string' &&
          (
            field[:name].downcase.include?('next') ||
            field[:name].downcase.include?('page') ||
            field[:name].downcase.include?('link')
          ) &&
          !(
            field[:name].downcase.include?('token') ||
            field[:name].downcase.include?('cursor')
          )
      end
    end,

    is_new_or_updated_trigger: lambda do |connection, keyboard_map, path, endpoint,
                                          substituted_fields|
      is_search_operation = call('is_search_operation', connection,
                                 keyboard_map, path, endpoint,
                                 substituted_fields)
      result_so_far = is_search_operation
      if result_so_far
        request_fields = call(
          'request_fields',
          connection,
          endpoint
        )
        timestamp_fields = call(
          'get_timestamp_request_fields',
          connection,
          request_fields
        )
        result_so_far = timestamp_fields.present?
      end
      if result_so_far
        response_fields = call(
          'response_fields',
          connection,
          'search',
          endpoint
        )
        result_so_far = response_fields.present?
      end
      if result_so_far
        list_fields = call(
          'get_search_operation_response_list_fields',
          connection,
          response_fields
        )
        result_so_far = list_fields.present?
      end
      if result_so_far
        list_fields = list_fields.select do |field|
          record_fields = field[:properties]
          timestamp_fields = call(
            'get_record_timestamp_fields',
            connection,
            record_fields
          )
          timestamp_fields.present?
        end
        result_so_far = list_fields.present?
      end
      if result_so_far
        list_fields = list_fields.select do |field|
          record_fields = field[:properties]
          identifier_fields = call(
            'get_record_identifier_fields',
            connection,
            record_fields
          )
          identifier_fields.present?
        end
        result_so_far = list_fields.present?
      end
      result_so_far
    end,

    is_delete_operation: lambda do |connection, keyword_map, _endpoint, substituted_fields|
      call(
        'match_operation_fields_with_keywords',
        connection,
        substituted_fields,
        keyword_map['delete']
      )
    end,

    is_update_operation: lambda do |connection, keyword_map, _endpoint, substituted_fields|
      call(
        'match_operation_fields_with_keywords',
        connection,
        substituted_fields,
        keyword_map['update']
      )
    end,

    is_create_operation: lambda do |connection, keyword_map, _endpoint, substituted_fields|
      call(
        'match_operation_fields_with_keywords',
        connection,
        substituted_fields,
        keyword_map['create']
      )
    end,

    is_get_operation: lambda do |connection, keyword_map, path, endpoint, substituted_fields|
      get_request_fields = call(
        'request_fields',
        connection,
        endpoint
      )
      has_id_or_ids_request_field = get_request_fields.select do |field|
        field[:name] == 'id' || field[:name] == 'ids' ||
          field[:name] == 'ID' || field[:name] == 'IDs' ||
          field[:name] == 'Id' || field[:name] == 'Ids'
      end.present?

      record_id_field_name = connection.dig('advanced', 'record_id_field_name')
      record_id_field_name = connection['record_id_field_name'] if record_id_field_name.nil?
      path_has_id_placeholder_somewhere_re = if record_id_field_name.blank?
                                               /[iI][dD]}/
                                             else
                                               /#{record_id_field_name}}/i
                                             end
      call(
        'match_operation_fields_with_keywords',
        connection,
        substituted_fields,
        keyword_map['get']
      ) &&
        (
          path.match?(path_has_id_placeholder_somewhere_re) ||
          has_id_or_ids_request_field
        ) &&
        !call(
          'match_operation_fields_with_keywords',
          connection,
          substituted_fields,
          keyword_map['search']
        )
    end,

    get_keyword_map: lambda do |_connection|
      create_keywords = %w[posts post
                           creates\ or\ updates create\ or\ update
                           creates\ new
                           create\ new
                           create\ a\ new
                           creates\ a\ new
                           creates create adds add uploads upload]
      update_keywords = %w[puts put
                           patches patch
                           creates\ or\ updates create\ or\ update
                           updates update sets set uploads upload
                           edits edit
                           modifies modify
                           manipulates manipulate]
      delete_keywords = %w[deletes delete removes remove kills kill destroy]
      get_keywords = %w[gets
                        single
                        get\ single
                        get
                        downloads
                        download
                        returns
                        return
                        finds
                        find
                        shows
                        show
                        retrieves
                        retrieve
                        provides
                        provide
                        query
                        reads
                        read]
      search_keywords = %w[returns\ a\ collection\ of
                           return\ a\ collection\ of
                           returns\ collection\ of
                           return\ collection\ of
                           returns\ a\ list\ of
                           return\ a\ list\ of
                           returns\ list\ of
                           return\ list\ of
                           returns\ a\ collection
                           return\ a\ collection
                           returns\ collection
                           return\ collection
                           returns\ a\ list
                           return\ a\ list
                           returns\ list
                           return\ list
                           list\ or\ find
                           lists\ or\ finds
                           gets\ a\ collection\ of
                           gets\ a\ collection
                           get\ collection\ of
                           get\ collection
                           get\ list\ of
                           get\ list
                           get\ all
                           gets\ all
                           list\ all
                           lists\ all
                           lists
                           list
                           searches
                           search
                           retrieves\ objects
                           retrieve\ records
                           retrieves\ all
                           retrieve\ all]
      {
        'create' => create_keywords,
        'update' => update_keywords,
        'delete' => delete_keywords,
        'get' => get_keywords,
        'search' => search_keywords
      }
    end,

    # List of keywords that will be used to generate the labels
    # for the object picklist input field.
    # In case of multiple objects with same name, endpoint parameter will be
    # identified to append a pattern like "<object name> by <parameter name>".
    picklist_keyword_map: lambda do
      %w[ids id names name filter filters query]
    end,

    build_endpoint_pick_list: lambda do |connection, verb, tag|
      api_definition = call('get_api_definition', connection)
      openapi_version = call('get_openapi_version', api_definition)
      inheritance_map = call(
        'generate_component_schema_interitance_map',
        connection,
        api_definition
      )

      use_operation_names_for_grouping = connection.dig(
        'advanced',
        'use_operation_names_for_grouping'
      )
      if use_operation_names_for_grouping.nil?
        use_operation_names_for_grouping = connection['use_operation_names_for_grouping']
      end
      use_operation_names_for_grouping = true if use_operation_names_for_grouping.nil?
      use_operation_names_for_grouping = use_operation_names_for_grouping.is_true?

      keyword_map = call('get_keyword_map', connection)

      # loop through all the endpoints and it's operations
      pick_list = []
      api_definition['paths']&.each do |path, path_schema|
        path_schema = call(
          'dereference_path_item',
          connection,
          api_definition,
          inheritance_map,
          path_schema
        )
        %w[get post put patch delete].each do |operation_name|
          # skip if the operation is not available
          operation = path_schema[operation_name]
          next if operation.nil?

          # skip if operation should be filtered out
          next unless tag.blank? || (operation['tags'] || []).include?(tag)

          # skip if operation should be filtered out
          next unless call('filter_endpoint', connection, path, operation_name, operation)

          # skip if non of the request media types are supported
          request_media_types = call('get_request_media_types', connection, operation)
          next unless request_media_types.nil? || request_media_types.present?

          # skip if non of the response media types are supported
          expected_response_name = call(
            'get_default_expected_response_name',
            operation,
            verb
          )
          unless expected_response_name.nil?
            response_media_types = call(
              'get_response_media_types',
              connection,
              operation,
              expected_response_name
            )
          end
          next unless response_media_types.nil? || response_media_types.present?

          # get strip keywords
          case verb
          when 'get'
            strip_keywords = keyword_map['get']
          when 'create'
            strip_keywords = keyword_map['create']
          when 'update'
            strip_keywords = keyword_map['update']
          when 'delete'
            strip_keywords = keyword_map['delete']
          when 'search', 'new_or_updated_trigger'
            strip_keywords = keyword_map['search'] + keyword_map['get']
          end

          # get title
          title = if verb == 'execute'
                    call(
                      'get_operation_label_from_operation',
                      connection,
                      path,
                      operation
                    )
                  else
                    call(
                      'get_object_label_from_operation',
                      connection,
                      path,
                      verb,
                      operation,
                      strip_keywords || []
                    )
                  end
          next if title.blank?

          # build endpoint
          endpoint = {
            'title' => title,
            'path' => path,
            'method' => operation_name,
            'schema' => operation,
            'openapi_version' => openapi_version
          }
          endpoint_with_default_response = endpoint.merge(
            {
              'expected_response_name' => expected_response_name,
              'request_media_type' => request_media_types&.first,
              'response_media_type' => response_media_types&.first
            }
          )

          # apply field substitutions for endpoint grouping
          substituted_fields = call(
            'apply_text_substitutions_for_grouping',
            connection,
            path,
            operation
          )

          if use_operation_names_for_grouping
            is_create_action_post = operation_name == 'post' &&
                                    call('is_create_operation', connection,
                                         keyword_map, endpoint_with_default_response,
                                         substituted_fields)
            is_create_action_put = operation_name == 'put' &&
                                   call('is_create_operation', connection,
                                        keyword_map, endpoint_with_default_response,
                                        substituted_fields)
            is_create_action = is_create_action_post || is_create_action_put
            is_update_action_put = operation_name == 'put' &&
                                   call('is_update_operation', connection,
                                        keyword_map, endpoint_with_default_response,
                                        substituted_fields)
            is_update_action_post = operation_name == 'post' &&
                                    call('is_update_operation', connection,
                                         keyword_map, endpoint_with_default_response,
                                         substituted_fields)
            is_update_action_patch = operation_name == 'patch' &&
                                     call('is_update_operation', connection,
                                          keyword_map, endpoint_with_default_response,
                                          substituted_fields)
            is_update_action = (is_update_action_put ||
                               is_update_action_post ||
                               is_update_action_patch) && !is_create_action
            is_delete_action = operation_name == 'delete' &&
                               call('is_delete_operation', connection,
                                    keyword_map, endpoint_with_default_response,
                                    substituted_fields)
            is_search_action = operation_name == 'get' &&
                               call('is_search_operation', connection,
                                    keyword_map, path, endpoint_with_default_response,
                                    substituted_fields)
            is_get_action = !is_search_action &&
                            operation_name == 'get' &&
                            call('is_get_operation', connection,
                                 keyword_map, path, endpoint_with_default_response,
                                 substituted_fields)
            is_execute_action = (operation_name == 'get' &&
                                  !is_get_action &&
                                  !is_search_action) ||
                                (operation_name == 'put' &&
                                  !is_update_action_put &&
                                  !is_create_action_put) ||
                                (operation_name == 'post' &&
                                  !is_create_action_post &&
                                  !is_update_action_post) ||
                                (operation_name == 'patch' &&
                                  !is_update_action_patch) ||
                                (operation_name == 'delete' &&
                                  !is_delete_action)
            is_new_or_updated_trigger = operation_name == 'get' &&
                                        call('is_new_or_updated_trigger', connection,
                                             keyword_map, path, endpoint_with_default_response,
                                             substituted_fields)
          else # 'use_operation_names_for_grouping' is false
            is_create_action = call('is_create_operation', connection, keyword_map,
                                    endpoint_with_default_response, substituted_fields)
            is_update_action = !is_create_action &&
                               call('is_update_operation', connection, keyword_map,
                                    endpoint_with_default_response, substituted_fields)
            is_delete_action = !is_update_action &&
                               !is_create_action &&
                               call('is_delete_operation', connection, keyword_map,
                                    endpoint_with_default_response, substituted_fields)
            is_search_action = !is_delete_action &&
                               !is_update_action &&
                               !is_create_action &&
                               call('is_search_operation', connection,
                                    keyword_map, path, endpoint_with_default_response,
                                    substituted_fields)
            is_get_action = !is_delete_action &&
                            !is_update_action &&
                            !is_create_action &&
                            !is_search_action &&
                            call('is_get_operation', connection, keyword_map,
                                 path, endpoint_with_default_response, substituted_fields)
            is_execute_action = !is_search_action &&
                                !is_delete_action &&
                                !is_update_action &&
                                !is_create_action &&
                                !is_get_action
            is_new_or_updated_trigger = call('is_new_or_updated_trigger', connection,
                                             keyword_map, path, endpoint_with_default_response,
                                             substituted_fields)
          end

          case verb
          when 'get'
            add_pick_list_item = is_get_action
          when 'create'
            add_pick_list_item = is_create_action
          when 'update'
            add_pick_list_item = is_update_action
          when 'delete'
            add_pick_list_item = is_delete_action
          when 'search'
            add_pick_list_item = is_search_action
          when 'new_or_updated_trigger'
            add_pick_list_item = is_new_or_updated_trigger
          when 'execute'
            add_pick_list_item = is_execute_action
          end

          # skip if the operation should not be available for verb
          next unless add_pick_list_item

          # add operation to pick list
          pick_list.push(endpoint)
        end
      end

      picklist_keyword_map = call('picklist_keyword_map')

      # find the duplicate items in endpoints based on title
      duplicate_endpoint_sets = pick_list.group_by { |endpoint| endpoint['title'] }
      duplicate_endpoint_sets = duplicate_endpoint_sets.values.select { |group| group.length > 1 }
      duplicate_endpoint_sets.each do |endpoints|
        # collect all the names of all parameters
        parameter_names = []
        endpoints.each do |endpoint|
          endpoint.dig('schema', 'parameters')&.each do |parameter|
            parameter_names.push(parameter['name'])
          end
        end

        # get the duplicate parameter names from endpoints
        duplicate_names = parameter_names.group_by { |name| name }.
                          values.
                          select { |group| group.length > 1 }.
                          flatten

        # remove duplicate parameters from endpoints
        endpoints_no_duplicate_parameters = endpoints.map do |endpoint|
          filtered_parameters = endpoint.dig('schema', 'parameters')&.reject do |parameter|
            duplicate_names.include?(parameter['name'])
          end
          schema = endpoint['schema'].merge(
            { 'parameters' => filtered_parameters || [] }
          )
          endpoint.merge({ 'schema' => schema })
        end

        # lookup the set of maching keyboards by parameters
        endpoints_with_selected_params = endpoints_no_duplicate_parameters.map do |endpoint|
          filtered_parameters = endpoint.dig('schema', 'parameters')&.select do |parameter|
            picklist_keyword_map.select do |keyword|
              parameter['name']&.ends_with?("_#{keyword}") || parameter['name'] == keyword
            end&.present?
          end
          schema = endpoint['schema'].merge({ 'parameters' => filtered_parameters || [] })
          endpoint.merge({ 'schema' => schema })
        end

        # compose a new title for each endpoint
        endpoints.each_with_index do |endpoint, index|
          parameters = endpoints_with_selected_params[index].dig(
            'schema',
            'parameters'
          )
          if parameters.present?
            parameters = parameters.map { |field| call('labelize', field['name']) }.join(', ')
            title = "#{endpoint['title']} by #{parameters}"
          end

          parameters = endpoints_no_duplicate_parameters[index].dig('schema', 'parameters')
          if parameters.present? && title.blank?
            parameters = parameters.map { |field| call('labelize', field['name']) }.join(', ')
            title = "#{endpoint['title']} by #{parameters}"
          end

          endpoint['title'] = title unless title.blank?
        end
      end

      # return the list of endpoint operations
      pick_list.map do |endpoint|
        [endpoint['title'], endpoint.to_json, call('get_endpoint_hints', connection, endpoint)]
      end
    end,

    get_supported_request_media_types: lambda do
      [
        %r{^application/(.+\+)?json(;.+)?$},
        'application/x-www-form-urlencoded',
        'multipart/form-data'
      ]
    end,

    get_request_media_types: lambda do |connection, operation_object|
      api_definition = call('get_api_definition', connection)
      openapi_version = call('get_openapi_version', api_definition)
      method_prefix = call('get_openapi_version_method_prefix', openapi_version)
      call(
        "#{method_prefix}get_request_media_types",
        connection,
        operation_object
      )
    end,

    openapi_v2_get_request_media_types: lambda do |connection, operation_object|
      api_definition = call('get_api_definition', connection)
      consumes = api_definition['consumes']
      consumes = operation_object['consumes'] unless consumes.present?
      if consumes.present?
        all_supported = call('get_supported_request_media_types')
        consumes.reject do |a_media_type|
          all_supported.find do |a_supported|
            if a_supported.is_a?(String)
              a_media_type == a_supported
            else
              a_media_type.match? a_supported
            end
          end.nil?
        end
      end
    end,

    openapi_v3_get_request_media_types: lambda do |_connection, operation_object|
      request_schema_map = operation_object.dig('requestBody', 'content')
      if request_schema_map.present?
        all_supported = call('get_supported_request_media_types')
        request_schema_map.keys.reject do |a_media_type|
          all_supported.find do |a_supported|
            if a_supported.is_a?(String)
              a_media_type == a_supported
            else
              a_media_type.match? a_supported
            end
          end.nil?
        end
      end
    end,

    get_supported_response_media_types: lambda do
      [
        %r{^application/(.+\+)?json(;.+)?$},
        '*/*',
        'application/octet-stream'
      ]
    end,

    get_response_media_types: lambda do |connection, operation_object, expected_response_name|
      api_definition = call('get_api_definition', connection)
      openapi_version = call('get_openapi_version', api_definition)
      method_prefix = call('get_openapi_version_method_prefix', openapi_version)
      call(
        "#{method_prefix}get_response_media_types",
        connection,
        operation_object,
        expected_response_name
      )
    end,

    openapi_v2_get_response_media_types: lambda do |connection, operation_object,
                                                    _expected_response_name|
      api_definition = call('get_api_definition', connection)
      produces = api_definition['produces']
      produces = operation_object['produces'] unless produces.present?
      if produces.present?
        all_supported = call('get_supported_response_media_types')
        produces.reject do |a_media_type|
          all_supported.find do |a_supported|
            if a_supported.is_a?(String)
              a_media_type == a_supported
            else
              a_media_type.match? a_supported
            end
          end.nil?
        end
      end
    end,

    openapi_v3_get_response_media_types: lambda do |_connection, operation_object,
                                                    expected_response_name|
      # TODO: dereference response
      schema_map = operation_object.dig(
        'responses',
        expected_response_name,
        'content'
      )
      if schema_map.present?
        all_supported = call('get_supported_response_media_types')
        schema_map.keys.reject do |a_media_type|
          all_supported.find do |a_supported|
            if a_supported.is_a?(String)
              a_media_type == a_supported
            else
              a_media_type.match? a_supported
            end
          end.nil?
        end
      end
    end,

    convert_common_mark_to_field_hint_format: lambda do |connection,
                                                         common_mark,
                                                         documentation_href|
      if common_mark.present?
        common_mark = common_mark.strip
        common_mark = common_mark.gsub('<p>', '<br>')
        common_mark = common_mark.gsub('</p>', '<br>')
        common_mark = common_mark.gsub(/\R/, '<br>')
        common_mark = common_mark.gsub('\\n', '<br>')

        allow_multi_paragraph_hint = call('get_allow_multi_paragraph_hint', connection)
        first_break_index_one = common_mark.index('<br>')
        first_break_index_two = common_mark.index('<br/>')
        if !first_break_index_one.nil? && !first_break_index_two.nil?
          first_break_index = [first_break_index_one, first_break_index_two].min
        elsif first_break_index_one.nil? && !first_break_index_two.nil?
          first_break_index = first_break_index_two
        elsif !first_break_index_one.nil? && first_break_index_two.nil?
          first_break_index = first_break_index_one
        end
        unless first_break_index.nil? || allow_multi_paragraph_hint
          common_mark = common_mark[0..first_break_index - 1]
          common_mark = common_mark.strip
          common_mark = common_mark.gsub(/(.*)\W$/, '\1')
          if documentation_href.blank?
            documentation_href = call('get_documentation_href', connection)
          end
          if documentation_href&.present?
            anchor = "<a href='#{documentation_href}' target='_blank'>here</a>"
            common_mark = "#{common_mark}. Click #{anchor} for details."
          else
            common_mark = "#{common_mark}. See documentation for details."
          end
        end

        common_mark = common_mark.gsub(/\*\*(.+)\*\*/, '<b>\1</b>')
        common_mark = common_mark.gsub(/\*(.+)\*/, '<b>\1</b>')

        # external links
        external_links = connection.dig('advanced', 'external_links')
        external_links = connection['external_links'] if external_links.nil?
        external_links&.each do |link|
          tag = link['key']
          base_url = link['value']
          next if tag.blank? || base_url.blank?

          common_mark = common_mark.gsub(
            /\[([^\]]+)\]\(#{tag}:([^)]+)\)/,
            "<a href='#{base_url}\\2' target='_blank'>\\1</a>"
          )
        end
        # raw http(s) links
        common_mark = common_mark.gsub(
          /\[([^\]]+)\]\((https?:[^)]+)\)/,
          "<a href='\\2' target='_blank'>\\1</a>"
        )
        # strip remaining links
        common_mark = common_mark.gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')

        # make first character upper case
        common_mark = "#{common_mark[0].upcase}#{common_mark[1..-1]}" if common_mark.present?
      end
      common_mark
    end,

    labelize: lambda do |name|
      name = name&.to_s
      name = name&.gsub(/{.+}/, '')
      # replace all non-word characters with a space
      name = name&.gsub(/\W|-|_/, ' ')
      name = name&.strip
      name = name&.gsub(/([a-z])([A-Z])/, '\1 \2')
      name = name&.gsub(/[A-Z][a-z]+/) { |word| word.downcase }
      name = name&.gsub(/^\w/) { |word| word.upcase }
      %w[aws ip ips ids id uid].each do |keyword|
        name = name&.gsub(/ #{keyword} /, " #{keyword.upcase} ")
        name = name&.gsub(/^#{keyword} /, "#{keyword.upcase} ")
        name = name&.gsub(/ #{keyword}$/, " #{keyword.upcase}")
        name = name&.gsub(/^#{keyword}$/, keyword.upcase)

        name = name&.gsub(/(#{keyword.upcase})(\w.*)/, '\1 \2')
      end

      name
    end,

    # This method is for Custom action
    make_schema_builder_fields_sticky: lambda do |schema|
      schema.map do |field|
        if field['properties'].present?
          field['properties'] = call('make_schema_builder_fields_sticky',
                                     field['properties'])
        end
        field['sticky'] = true

        field
      end
    end,

    # Formats input/output schema to replace any special characters in name,
    # without changing other attributes (method required for custom action)
    format_schema: lambda do |input|
      input&.map do |field|
        if (props = field[:properties])
          field[:properties] = call('format_schema', props)
        elsif (props = field['properties'])
          field['properties'] = call('format_schema', props)
        end
        if (name = field[:name])
          field[:label] = field[:label].presence || name.labelize
          field[:name] = name.
                         gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        elsif (name = field['name'])
          field['label'] = field['label'].presence || name.labelize
          field['name'] = name.
                          gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        end
        if field[:toggle_field].present?
          toggle_fields = call('format_schema', [field[:toggle_field]])
          field[:toggle_field] = toggle_fields[0]
        end
        field
      end
    end,

    # Formats payload to inject any special characters that previously removed
    format_payload: lambda do |payload|
      if payload.is_a?(Array)
        payload.map do |array_value|
          call('format_payload', array_value)
        end
      elsif payload.is_a?(Hash)
        payload.each_with_object({}) do |(key, value), hash|
          key = key.to_s
          key = key.gsub(/__[0-9a-fA-F]+__/) do |string|
            string.gsub(/__/, '').decode_hex.as_utf8
          end
          value = call('format_payload', value) if value.is_a?(Array) || value.is_a?(Hash)
          hash[key] = value
        end
      else
        payload
      end
    end,

    # Formats response to replace any special characters with valid strings
    # (method required for custom action)
    format_response: lambda do |response|
      if response.is_a?(Array)
        response.compact.map do |array_value|
          call('format_response', array_value)
        end
      elsif response.is_a?(Hash)
        response.compact.each_with_object({}) do |(key, value), hash|
          key = key.to_s
          key = key.gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
          value = call('format_response', value) if value.is_a?(Array) || value.is_a?(Hash)
          hash[key] = value
        end
      else
        response
      end
    end,

    get_max_schema_depth: lambda do |connection|
      depth = connection.dig('advanced', 'max_schema_depth')
      depth = connection.dig('advanced', 'max_dereference_depth') if depth.blank?
      depth = connection['max_dereference_depth'] if depth.blank?
      depth = nil if depth.blank?
      depth = depth.to_i if depth.is_a?(String)
      depth || 20
    end,

    get_max_recursion_depth: lambda do |connection|
      depth = connection.dig('advanced', 'max_recursion_depth')
      depth = connection['max_recursion_depth'] if depth.blank?
      depth = nil if depth.blank?
      depth = depth.to_i if depth.is_a?(String)
      depth || 3
    end,

    get_object_label_map: lambda do |connection|
      object_label_map = connection.dig('advanced', 'object_label_map')
      object_label_map = {} if object_label_map.nil?
      if object_label_map.is_a?(Array)
        object_label_map = object_label_map.each_with_object({}) do |item, map|
          map[item['operation_id']] = item['label']
        end
      end
      object_label_map
    end,

    get_documentation_href: lambda do |connection|
      documentation_href = connection.dig('advanced', 'documentation_href')
      documentation_href = connection['documentation_href'] if documentation_href.nil?
      documentation_href
    end,

    get_allow_multi_paragraph_hint: lambda do |connection|
      allow_multi_paragraph_hint = connection.dig('advanced', 'allow_multi_paragraph_hint')
      if allow_multi_paragraph_hint.nil?
        allow_multi_paragraph_hint = connection['allow_multi_paragraph_hint']
      end
      unless allow_multi_paragraph_hint.nil?
        allow_multi_paragraph_hint = allow_multi_paragraph_hint.is_true?
      end
      allow_multi_paragraph_hint || false
    end,

    filter_endpoint: lambda do |connection, path, operation_name, operation|
      endpoint_filter_rules = connection.dig('advanced', 'endpoint_filter_rules') || []

      # check if endpoint is included
      included = nil
      endpoint_filter_rules.each do |rule|
        next unless rule['type'] == 'include'
        next if included == true # 'break' keywork not allowed

        included = call(
          'match_filter_rule',
          rule,
          path,
          operation_name,
          operation
        )
      end

      # assume true if no 'include' rules are defined
      included = true if included.nil?

      # check if endpoint is excluded / filtered out
      endpoint_filter_rules.each do |rule|
        next unless rule['type'] == 'exclude'
        next unless included # 'break' keywork not allowed

        match = call(
          'match_filter_rule',
          rule,
          path,
          operation_name,
          operation
        )
        included = false if match
      end

      # final result
      included
    end,

    match_filter_rule: lambda do |rule, path, operation_name, operation|
      has_match = true

      if has_match
        has_match = rule['http_method']&.strip&.split(',')&.include?(operation_name)
        has_match = true if has_match.nil?
      end

      if has_match
        operation_tags = operation['tags'] || []
        tag_re = /#{rule['tag']}/ unless rule['tag'].blank?
        has_match = operation_tags.any? { |tag| tag.match?(tag_re) } unless tag_re.nil?
        has_match = true if has_match.nil?
      end

      if has_match
        operation_id = operation['operationId'] || ''
        operation_id_re = /#{rule['operation_id']}/ unless rule['operation_id'].blank?
        has_match = operation_id.match?(operation_id_re) unless operation_id_re.nil?
        has_match = true if has_match.nil?
      end

      if has_match
        path_re = /#{rule['path']}/ unless rule['path'].blank?
        has_match = path.match?(path_re) unless path_re.nil?
        has_match = true if has_match.nil?
      end

      has_match
    end

  }
}
