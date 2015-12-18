<%@ Page Language="C#" Debug="true" %>

<%@ Import Namespace="System.Net" %>

<% Response.ContentType = "application/json"; %>
<% Response.AddHeader("Access-Control-Allow-Origin", "*"); %>

<script runat="server">

    protected override void OnLoad(EventArgs e)
    {
        string url = Server.UrlDecode(Request.QueryString["url"]);
        if (string.IsNullOrEmpty(url))
        {
            return;
        }

        try
        {
            using (var webClient = new System.Net.WebClient())
            {
                webClient.Headers["X-Octopus-ApiKey"] = "API-MGKZDCIKCI9JEY8YS4UVZZZO";
                webClient.Headers["Accept"] = "application/json";
                var json = webClient.DownloadString(url);
                Response.Write(json);
            }
        }
        catch
        {
            Response.Write("");
        }
    }

</script>
