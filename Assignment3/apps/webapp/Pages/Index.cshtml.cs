using Assignment3.WebApp.Services;
using Azure.Messaging.ServiceBus;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Assignment3.WebApp.Pages;

public class IndexModel : PageModel
{
    private readonly IServiceBusSenderService _sender;
    private readonly ILogger<IndexModel> _logger;

    [BindProperty]
    public string? MessageText { get; set; }

    /// <summary>Displayed to the user after a send attempt.</summary>
    public string? StatusMessage { get; private set; }

    /// <summary>True if the last operation resulted in an error.</summary>
    public bool HasError { get; private set; }

    public IndexModel(IServiceBusSenderService sender, ILogger<IndexModel> logger)
    {
        _sender = sender;
        _logger = logger;
    }

    public void OnGet() { }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(MessageText))
        {
            HasError      = true;
            StatusMessage = "Message cannot be empty. Please enter some text and try again.";
            return Page();
        }

        try
        {
            await _sender.SendMessageAsync(MessageText, cancellationToken);

            StatusMessage = "Message sent successfully! The Function App will write it to Table Storage.";
            MessageText   = null; // Clear the textarea on success.
            _logger.LogInformation("User submitted a message via the web UI.");
        }
        catch (ServiceBusException ex) when (ex.IsTransient)
        {
            HasError      = true;
            StatusMessage = "A transient error occurred while sending the message. Please try again.";
            _logger.LogWarning(ex, "Transient Service Bus error while sending message.");
        }
        catch (Exception ex)
        {
            HasError      = true;
            StatusMessage = $"Failed to send message: {ex.Message}";
            _logger.LogError(ex, "Unexpected error while sending message to Service Bus.");
        }

        return Page();
    }
}
