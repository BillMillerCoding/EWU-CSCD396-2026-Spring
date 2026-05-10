using Azure.Data.Tables;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Assignment3.FunctionApp.Functions;

/// <summary>
/// Listens on the "messages" Service Bus queue and persists each received
/// message as a row in Azure Table Storage.
///
/// Authentication is fully passwordless:
///   - Service Bus:   Function App managed identity with "Azure Service Bus Data Receiver" role.
///   - Table Storage: Function App managed identity with "Storage Table Data Contributor" role.
///
/// Connection settings (from Terraform app_settings):
///   ServiceBusConnection__fullyQualifiedNamespace — resolved by the SDK via managed identity.
///   OutputStorageAccountName                      — used in Program.cs to build the TableServiceClient.
/// </summary>
public class ServiceBusReceiver
{
    private readonly TableServiceClient _tableServiceClient;
    private readonly ILogger<ServiceBusReceiver> _logger;

    private const string TableName = "messages";

    public ServiceBusReceiver(TableServiceClient tableServiceClient, ILogger<ServiceBusReceiver> logger)
    {
        _tableServiceClient = tableServiceClient;
        _logger             = logger;
    }

    [Function(nameof(ServiceBusReceiver))]
    public async Task Run(
        // The "Connection" value maps to the app setting prefix
        // "ServiceBusConnection__fullyQualifiedNamespace" which is set by Terraform.
        [ServiceBusTrigger("messages", Connection = "ServiceBusConnection")]
        string messageBody,
        FunctionContext context)
    {
        _logger.LogInformation(
            "Service Bus message received. BodyLength={Length}",
            messageBody.Length);

        // Ensure the table exists. CreateIfNotExistsAsync is idempotent and
        // fast after the first call (Azure caches the existence check).
        var tableClient = _tableServiceClient.GetTableClient(TableName);
        await tableClient.CreateIfNotExistsAsync();

        // Partition by calendar date so rows are easy to browse in Azure Storage Explorer.
        var entity = new TableEntity(
            partitionKey: DateTimeOffset.UtcNow.ToString("yyyy-MM-dd"),
            rowKey:       Guid.NewGuid().ToString())
        {
            ["MessageBody"] = messageBody,
            ["ReceivedAt"]  = DateTimeOffset.UtcNow,
            ["BodyLength"]  = messageBody.Length,
            ["FunctionId"]  = context.InvocationId
        };

        await tableClient.UpsertEntityAsync(entity);

        _logger.LogInformation(
            "Message stored in table '{Table}'. PartitionKey={Partition}, RowKey={Row}",
            TableName, entity.PartitionKey, entity.RowKey);
    }
}
