using Assignment3.WebApp.Services;

var builder = WebApplication.CreateBuilder(args);

// ── Services ──────────────────────────────────────────────────────────────────

builder.Services.AddRazorPages();

// ServiceBusSenderService is thread-safe and designed for long-lived use, so
// register as a singleton to reuse the underlying AMQP connection across requests.
builder.Services.AddSingleton<IServiceBusSenderService, ServiceBusSenderService>();

// ── Pipeline ──────────────────────────────────────────────────────────────────

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // HSTS only applies when the app is behind a TLS endpoint.
    // Azure Container Apps ingress handles TLS termination externally.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();

app.MapRazorPages();

app.Run();
