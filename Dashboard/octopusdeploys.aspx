<%@ Page Language="C#" Debug="true" %>

<html>
<head>
    <title>Octopus Deploys</title>
    <script src="http://code.jquery.com/jquery-2.1.3.min.js"></script>
    <script runat="server">

        protected void Page_Load(object sender, EventArgs e)
        {

        }

    </script>
    <script>

        var octopusProxy = "http://iisserver/Jira_Dashboard_Extensions/octopusproxy.aspx" + location.search;

    </script>
    <style>
        body {
            background-color: white;
            color: black;
            font-family: 'Courier New', Courier, 'Lucida Sans Typewriter', 'Lucida Typewriter', monospace;
        }

        .WallBoard {
            background-color: black;
            color: white;
        }

        #Filter {
            font-size: 22pt;
        }

        .Build {
            width: 200px;
            height: 80px;
            margin: 5px;
            float: left;
            word-wrap: break-word;
            font-size: 12pt;
        }

        .SUCCESS {
            background-color: green;
        }

        .FAILURE, .FAILED {
            background-color: red;
            font-size: 24pt;
            width: 400px;
            height: 160px;
            margin: 10px;
        }

        .Warning, .Inconclusive {
            color: orange;
        }
    </style>
</head>
<body>

    <div id="Filter">Octopus Deploys for </div>

    <div id="Environments"></div>

    <script>

        $(document).ready(function () {

            $.ajaxSetup({ timeout: 10000 }); //in milliseconds

            $("#Filter").hide();

            if (document.referrer.indexOf("/plugins/servlet/gadgets/") > 0) {
                $("body").addClass("Wallboard");
            }

            $.ajax({
                url: octopusProxy,
                type: "GET",
                complete: function (xhr, status) {
                    if (status === 'error' || !xhr.responseText) {
                        $("#Jira").append(status);
                        return;
                    } else if (status === 'timeout') {
                        $("#Filter").text("Octopus timeout").show();
                        return;
                    } else {
                        var data = jQuery.parseJSON(xhr.responseText);
                        if (data.Error) {
                            $("#Filter").text("Error: " + data.Error).show();
                            return;
                        }
                        $("#Filter").append(data.ProjectFilter).show();
                        $.each(data.Environments, function (i, v) {
                            for (var projectName in v) {
                                var project = v[projectName];
                                var build = "";
                                build += "<div class='Build " + project.Status + "'>";
                                build += "<div>";
                                build += projectName.replace("RACQESB.", "");
                                build += "</div>";
                                build += "<div>";
                                build += project.Number;
                                build += "</div>";
                                if (project.SpecFlow.Outcome) {
                                    build += "<span class='specflowoutcome " + project.SpecFlow.Outcome + "'>SpecFlow:";
                                    build += project.SpecFlow.Outcome;
                                    build += "</span>";
                                }
                                build += "</div>";
                                $("#Environments").append(build);
                            }
                        });
                    }
                }
            });
        });

    </script>
</body>
</html>
