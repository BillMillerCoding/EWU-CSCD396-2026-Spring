using Azure.Data.Tables;
using Azure.Identity;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, services) =>
    {
        // Wire up Application Insights for the isolated worker model.
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        // Register a singleton TableServiceClient using Managed Identity (DefaultAzureCredential).
        // OutputStorageAccountName is set by Terraform in the Function App app settings.
        var storageAccountName = context.Configuration["OutputStorageAccountName"]
            ?? throw new InvalidOperationException(
                "OutputStorageAccountName app setting is not configured. " +
                "Ensure the Terraform infra has been applied.");

        var tableEndpoint = new Uri($"https://{storageAccountName}.table.core.windows.net");
        services.AddSingleton(new TableServiceClient(tableEndpoint, new DefaultAzureCredential()));
    })
    .Build();

await host.RunAsync();
