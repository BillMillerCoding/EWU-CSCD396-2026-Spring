using Azure.Identity;
using Azure.Messaging.ServiceBus;

namespace Assignment3.WebApp.Services;

public interface IServiceBusSenderService
{
    /// <summary>Sends a plain-text message to the configured Service Bus queue.</summary>
    Task SendMessageAsync(string messageBody, CancellationToken cancellationToken = default);
}

/// <summary>
/// Sends messages to Azure Service Bus using Managed Identity (DefaultAzureCredential).
/// In Azure, the Container App's system-assigned identity is used automatically.
/// Locally, credentials are resolved via az login, environment variables, or VS developer credentials.
/// </summary>
public sealed class ServiceBusSenderService : IServiceBusSenderService, IAsyncDisposable
{
    private readonly ServiceBusClient _client;
    private readonly ServiceBusSender _sender;
    private readonly ILogger<ServiceBusSenderService> _logger;

    public ServiceBusSenderService(IConfiguration config, ILogger<ServiceBusSenderService> logger)
    {
        _logger = logger;

        var namespaceFqdn = config["ServiceBus:Namespace"]
            ?? throw new InvalidOperationException(
                "ServiceBus:Namespace is not configured. " +
                "Set the 'ServiceBus__Namespace' environment variable or update appsettings.json.");

        var queueName = config["ServiceBus:QueueName"]
            ?? throw new InvalidOperationException(
                "ServiceBus:QueueName is not configured. " +
                "Set the 'ServiceBus__QueueName' environment variable or update appsettings.json.");

        // DefaultAzureCredential tries, in order:
        //   1. Environment variables (CI/CD)
        //   2. Managed Identity (Azure hosting — Container App)
        //   3. Azure CLI (local development)
        //   4. Visual Studio / VS Code credentials
        _client = new ServiceBusClient(namespaceFqdn, new DefaultAzureCredential());
        _sender = _client.CreateSender(queueName);

        _logger.LogInformation(
            "ServiceBusSenderService initialized. Namespace={Namespace}, Queue={Queue}",
            namespaceFqdn, queueName);
    }

    public async Task SendMessageAsync(string messageBody, CancellationToken cancellationToken = default)
    {
        var message = new ServiceBusMessage(messageBody)
        {
            MessageId        = Guid.NewGuid().ToString(),
            ContentType      = "text/plain",
            ApplicationProperties =
            {
                ["SubmittedAt"] = DateTimeOffset.UtcNow.ToString("o"),
                ["Source"]      = "Assignment3WebApp"
            }
        };

        _logger.LogInformation("Sending message {MessageId} to Service Bus.", message.MessageId);

        // ServiceBusException is typically transient; bubble it up to the page model
        // so the UI can surface a meaningful error to the user.
        await _sender.SendMessageAsync(message, cancellationToken);

        _logger.LogInformation("Message {MessageId} sent successfully.", message.MessageId);
    }

    public async ValueTask DisposeAsync()
    {
        await _sender.DisposeAsync();
        await _client.DisposeAsync();
    }
}
