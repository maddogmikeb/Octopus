<html>
<head>
    <title>Octopus Deploys</title>
    <script src="http://code.jquery.com/jquery-2.1.3.min.js"></script>
    <style>
        * {
            font-size: 12px;
        }

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

        .SUCCESS {
            background-color: green;
        }

        .FAILURE, .FAILED {
            background-color: red;
            font-size: 16pt;
        }

        .Cancelling, .Executing, .Timedout {
            background-color: yellow;
        }

        .status {
            float: right;
            width: 100%;
            text-align: center;
        }

        .projectName {
            word-wrap: break-word;
        }

        .spacer {
            width: 0px;
            display: inline-block;
        }

        #DeployDetails > table > thead > tr {
            text-align: center;
        }

        .version {
            text-align: right;
            width: 90%;
            padding: 5px;
        }
    </style>
</head>
<body>

	<audio preload="auto" id="failureSound">
		<source src="failure.wav" type="audio/wav">
	</audio>
	
    <div id="Filter">Octopus Deploys for </div>

    <section id="DeployDetails">
        <table>
            <thead>
                <tr>
                    <td>
                        <div id="Loading">
                            Loading...
                        </div>
                    </td>
                </tr>
            </thead>
            <tbody>
            </tbody>
        </table>
    </section>

    <div id="console"></div>

    <script>

        var codebase = "http://iisserver/Jira_Dashboard_Extensions/";

        var octopusBase = "http://octopusdeploy.local";
        var octopusProjectGroups = octopusBase + "/octopusdeploy/api/ProjectGroups/all";
        var octopusProjects = octopusBase + "/octopusdeploy/api/Projects/";
        var octopusEnvironments = octopusBase + "/octopusdeploy/api/environments";
        var octopusDelpoyments = octopusBase + "/octopusdeploy/api/deployments?take=1";
		var queries = {};
   
        $(document).ready(function () {

            $("#Filter").hide();

            if (document.referrer.indexOf("/plugins/servlet/gadgets/") > 0) {
                $("body").addClass("Wallboard");
            }
         
            $.each(document.location.search.substr(1).split('&'), function (c, q) {
                var i = q.split('=');
                queries[i[0].toString()] = i[1].toString();
            });

            GetOctopusDetails(queries["projectid"], queries["environments"]);
        });

        if (!String.prototype.replaceLast) {
            String.prototype.replaceLast = function (find, replace) {
                var index = this.lastIndexOf(find);
                if (index >= 0) {
                    return this.substring(0, index) + replace + this.substring(index + find.length);
                }
                return this.toString();
            };
        }

        $(document).ajaxStart(function () {
            $("#Loading").show();
        });

        $(document).ajaxStop(function () {
            if (0 === $.active) {
                $("#Loading").hide();
				$("html, body").animate({ scrollTop: $(document).height() }, 3000);

				 $.each($("#DeployDetails > table > tbody > tr"), function (i, v)
				 {
					var texts = $.unique($.map($(v).find("[class='version']"), function(n, j) 
					{
						return $(n).text();
					}));
					if (texts && texts.length > 1)
					{
						$(v).append("<td>*</td>");
					}
				 });
            }
        });

        function callPaged(url, callBack) {
            $.getJSON(codebase + "/jsonfromoctopus.aspx?url=" + encodeURIComponent(url), function (data) {
                if (data.Links["Page.Next"]) {
                    setTimeout(function () { callPaged(octopusBase + data.Links["Page.Next"], callBack); }, 0);
                }
                callBack(data);
            });
        }

        function call(url, callBack) {
            $.getJSON(codebase + "/jsonfromoctopus.aspx?url=" + encodeURIComponent(url), function (data) {
                setTimeout(function () { callBack(data); }, 0);
            });
        }

        function GetOctopusDetails(octoprojectId, environments) {

            if (!environments) {
                return;
            }

            environments = environments.split(",");

            $("#DeployDetails").hide();

            callPaged(octopusProjects, function (data) {

                $.each(data.Items, function (i, v) {

                    var project = this;
                    project.Id = v.Id;
                    project.Name = v.Name;
                    project.Description = v.Description;

                    if (project.Description.indexOf(octoprojectId) == -1) {
                        return;
                    }

                    if ($("#DeployDetails > table > tbody > #" + project.Id.replace("-", "")).length == 0) {
                        var projectName = project.Name.replaceLast(".", ".<span class='spacer'>&nbsp</span>");
                        $("#DeployDetails > table > tbody").append("<tr id='" + project.Id.replace("-", "") + "'><td><div class='projectName'>" + projectName + "</div></td></tr>");
                    }

                    callPaged(octopusEnvironments, function (environmentData) {
                        var projectData = this;
                        projectData.Id = project.Id;
                        projectData.Name = project.Name;

                        $.each(environmentData.Items, function (i, environment) {

                            if ($.inArray(environment.Name, environments) == -1) {
                                return;
                            }

                            var safeEnvironmentId = environment.Id.replace("-", "");
                            var safeProjectId = projectData.Id.replace("-", "");

                            if ($("#DeployDetails > table > thead > tr > #" + safeEnvironmentId).length == 0) {
                                $("#DeployDetails > table > thead > tr").append("<td data-sortorder='" + environment.SortOrder + "' id='" + safeEnvironmentId + "'>" + environment.Name + "</td>");
                            } else {
                                //$("#DeployDetails > table > thead > tr > #" + safeEnvironmentId).css("display", "none");
                            }

                            if ($("#DeployDetails > table > tbody > #" + safeProjectId).find("td[data-environment='" + safeEnvironmentId + "'][data-projectid='" + safeProjectId + "']").length == 0) {
                                $("#DeployDetails > table > tbody > #" + safeProjectId).append("<td data-sortorder='" + environment.SortOrder + "' data-environment='" + safeEnvironmentId + "' data-projectid='" + safeProjectId + "'></td>");
                            } else {
                                //$("#DeployDetails > table > tbody > #" + safeProjectId).find("td[data-environment='" + safeEnvironmentId + "'][data-projectid='" + safeProjectId + "']").css("display", "none");
                            }

                            call(octopusDelpoyments + "&projects=" + projectData.Id + "&environments=" + environment.Id, function (deploymentData) {
                                var projectData = this;
                                projectData.Id = project.Id;
                                projectData.Name = project.Name;

                                if (deploymentData && deploymentData.Items && deploymentData.Items.length > 0) {
                                    var deployment = deploymentData.Items[0]; // only get the latest
                                    call(octopusBase + deployment.Links.Task, function (task) {
                                        var projectData = this;
                                        projectData.Id = project.Id;
                                        projectData.Name = project.Name;
                                        call(octopusBase + deployment.Links.Release, function (release) {
                                            var projectData = this;
                                            projectData.Id = project.Id;
                                            projectData.Name = project.Name;

                                            var safeEnvironmentId = environment.Id.replace("-", "");
                                            var safeProjectId = projectData.Id.replace("-", "");

                                            var taskDataCell = $("#DeployDetails > table > tbody > #" + safeProjectId).find("td[data-environment='" + safeEnvironmentId + "'][data-projectid='" + safeProjectId + "']");

											if (task.State != "Success") 
											{
												taskDataCell.html("<div class='releaseStatus " + task.State + "'><span class='status'>" + task.State + "</span></div>");
												$('failureSound').trigger('play');
											} else {
												taskDataCell.html("<div class='releaseStatus " + task.State + "'><div class='version'>" + release.Version + "</div></div>");
											}											
                                        });
                                    });
                                }
                            });
                        });
                    });
                });
            });

            $("#Filter").append(octoprojectId).show();
            $("#DeployDetails").fadeIn();
        }

    </script>
</body>
</html>
