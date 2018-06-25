require 'pact_broker/services'
require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/webhooks_decorator'
require 'pact_broker/api/decorators/webhook_decorator'
require 'pact_broker/api/contracts/webhook_contract'

module PactBroker
  module Api
    module Resources
      class AllWebhooks < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "POST", "OPTIONS", "OPTIONS"]
        end

        def create_path
          webhook_url next_uuid, base_url
        end

        def post_is_create?
          true
        end

        def malformed_request?
          if request.post?
            return invalid_json? || validation_errors?(webhook)
          end
          false
        end

        def to_json
          Decorators::WebhooksDecorator.new(webhooks).to_json(user_options: decorator_context(resource_title: "Webhooks"))
        end

        def from_json
          saved_webhook = webhook_service.create next_uuid, webhook, consumer, provider
          response.body = Decorators::WebhookDecorator.new(saved_webhook).to_json(user_options: { base_url: base_url })
        end

        private

        def validation_errors? webhook
          errors = webhook_service.errors(webhook)

          unless errors.empty?
            set_json_validation_error_messages(errors.messages)
          end

          !errors.empty?
        end

        def consumer
          webhook.consumer ? pacticipant_service.find_pacticipant_by_name(webhook.consumer.name) : nil
        end

        def provider
          webhook.provider ? pacticipant_service.find_pacticipant_by_name(webhook.provider.name) : nil
        end

        def webhooks
          webhook_service.find_all
        end

        def webhook
          @webhook ||= Decorators::WebhookDecorator.new(PactBroker::Domain::Webhook.new).from_json(request_body)
        end

        def next_uuid
          @next_uuid ||= webhook_service.next_uuid
        end
      end
    end
  end
end