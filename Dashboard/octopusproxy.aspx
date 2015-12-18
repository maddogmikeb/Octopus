<%@ Page Language="C#" Debug="false" %>

<%@ OutputCache Duration="600" VaryByParam="projectid" %>

<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="Octopus.Client" %>
<%@ Import Namespace="Sprache" %>
<%@ Import Namespace="Newtonsoft.Json" %>

<script runat="server">
	
    private string server = "http://octopusdeploy.local/";
    private string apiKey = "API-MGKZDCIKCI9JEY8YS4UVZZZO";

    private int timeOut;

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        timeOut = Server.ScriptTimeout;
        Server.ScriptTimeout = 10;
    }

    protected override void OnUnload(System.EventArgs e)
    {
        base.OnUnload(e);
        Server.ScriptTimeout = timeOut;
    }

    protected override void OnLoad(EventArgs e)
    {
        try
        {
            Response.Clear();
            Response.Cache.SetExpires(DateTime.Now.AddMinutes(10d));
            Response.Cache.SetCacheability(HttpCacheability.Public);
            Response.Cache.SetValidUntilExpires(true);
            Response.AddHeader("Access-Control-Allow-Origin", "*");
            Response.ContentType = "application/json; charset=utf-8";

            string projectid = Server.UrlDecode(Request.QueryString["projectid"]);
            if (string.IsNullOrEmpty(projectid))
            {
                Response.Write("{ \"ProjectFilter\" : \"Missing\" }");
                return;
            }

            string environmentsParam = Server.UrlDecode(Request.QueryString["environments"]);
            if (string.IsNullOrEmpty(environmentsParam))
            {
                Response.Write("{ \"ProjectFilter\" : \"" + projectid + "\", \"EnvironmentsFilter\" : \"Missing\" }");
                return;
            }

            var endpoint = new OctopusServerEndpoint(server, apiKey);
            var repository = new OctopusRepository(endpoint);

            var json = new StringBuilder();

            json.Append("{ \"Filter\" : \"" + projectid + "\", \"EnvironmentsFilter\" : \"" + environmentsParam + "\" , \"Environments\" : [ ");

            var projects = repository.Projects.FindMany(p => p.Description.Contains(projectid));

            var environments = repository.Environments.FindMany(p => environmentsParam.Split(',').Contains(p.Name));

            foreach (var env in environments)
            {
                json.Append("{ \"Name\" :\"" + env.Name + "\", \"Projects\" : [ ");
                bool hasProjects = false;
                foreach (var project in projects)
                {
                    json.Append("{ \"Name\" : \"" + project.Name + "\",");
                    json.Append("\"Id\" : \"" + project.Id + "\"");
                    hasProjects = true;

                    var deployment = repository.Deployments.FindOne(d => d.ProjectId == project.Id && d.EnvironmentId == env.Id);
                    if (deployment == null)
                    {
                        json.Append("},");
                        continue;
                    }

                    var release = repository.Releases.FindOne(r => deployment.Links["Release"] != null && deployment.Links["Release"].AsString().Contains(r.Id));
                    if (release == null)
                    {
                        json.Append("},");
                        continue;
                    }

                    json.Append(", \"LatestRelease\" : \"");
                    json.Append(release.Version);
                    json.Append("\"},");
                }
                if (hasProjects) json.Remove(json.ToString().Length - 1, 1);
                json.Append("] },");
            }

            json.Remove(json.ToString().Length - 1, 1);
            json.Append("] }");

            Response.Write(json.ToString());
        }
        catch (Exception ex)
        {
            Response.Clear();
            Response.AddHeader("Access-Control-Allow-Origin", "*");
            Response.ContentType = "application/json; charset=utf-8";
            Response.Write("{ \"Error\" : \"" + ex.GetType().ToString() + "\" }");
            //Response.Write("{ \"Error\" : \"" + Server.HtmlEncode(ex.Message.ToString()) + "\" }");
        }
    }
	
</script>
