

jQuery(document).ready(function() {
	//console.log("populate the settings interface");
	jQuery('#waiting_wheel').show();
	
	jQuery.getJSON('php/config.php', { 'action': 'get_config' }, function(data) {
		//jQuery('#waiting_wheel').fadeOut();
		if (typeof data['arrived'] != 'undefined') {
			jQuery('#arrived_folder').val(data['arrived']);
		}
		if (typeof data['log'] != 'undefined') {
			jQuery('#log_folder').val(data['log']);
		}
		if (typeof data['timeout'] != 'undefined') {
			jQuery('#timeout_value').val(data['timeout']);
		}
		if (typeof data['logging'].length > 0) {
			if (typeof data['logging'][0].logging_server_name != "undefined") {
				jQuery('#logging_server_name').val(data['logging'][0].logging_server_name);
			}
			if (typeof data['logging'][0].logging_server_port != "undefined") {
				jQuery('#logging_server_port').val(data['logging'][0].logging_server_port);
			}
			if (typeof data['logging'][0].logging_server_dbname != "undefined") {
				jQuery('#logging_server_dbname').val(data['logging'][0].logging_server_dbname);
			}
			if (typeof data['logging'][0].logging_server_driver != "undefined") {
				jQuery('#logging_server_driver').val(data['logging'][0].logging_server_driver);
			}
		}
		jQuery("#stream-info").children().remove();
		jQuery("#stream-info").append("<p>Number of configured streams: " + data['Streams'].length + "</p>");
		var txt = "<dl>";
		for (var i = 0; i < data['Streams'].length; i++) {
			txt += "<dt>" + data['Streams'][i].name + "</dt>";
			txt += "<dd>" + data['Streams'][i].description + "<br>" +
				"Triggered by: " + JSON.stringify(data['Streams'][i].trigger) + "<br>" +
				"Destination:" + JSON.stringify(data['Streams'][i].destination) + "</dd>";
		}
		txt += "</dl>";
		jQuery("#stream-info").append(txt);
	});
	
	
	setInterval(function () {
		jQuery.getJSON('php/logs.php', { 'action': 'summary' }, function(data) {
			jQuery('#waiting_wheel').fadeOut();
			if (typeof data['alife'] != 'undefined') {
				var v = jQuery("#alife_value").val();
				if (v != data['alife']) {
					jQuery('#alife_value').val(data['alife']).hide().fadeIn();
				}
			}
			if (typeof data["trigger_study"] != "undefined") {
				jQuery("#log_table").children().remove();
				var daysAgo = {};  // based on today we need an array of names and numbers				 
				for (var i = 0; i < data["trigger_study"].length; i++) {
					var l = data["trigger_study"][i].split(" ");
					var rest = l.slice(3).join(' ');
					var content = {};
					var txt = "";
					try {
						content = JSON.parse(rest);
						for(var j = 0; j < Object.keys(content).length; j++) {
							var name = Object.keys(content)[j];
							txt += "<h5>" + name + "</h5><p>" + ((content[name] == "\"\"")?"empty":content[name]) + "</p>";
						}
					} catch(e) {
						console.log("could not parse as json: " + rest);
						txt = rest;
					}
					var dat = dayjs(l[0],"YYYY-MM-DD");
					var today = dayjs();
					var diff = today.diff(dat, 'days');
					if (daysAgo[diff] == undefined) {
						daysAgo[diff] = [];
					} else {
						daysAgo[diff].push({ "date": l[0], "day": today.day(), "time": l[1] });
					}
					jQuery("#log_table").append("<tr><td>" + i + "</td><td>" + l[0] + " / " + l[1] + "</td><td>" + l[2] + "</td><td>" + txt + "</td></tr>");
				}
				var daysPrior = 14;
				var labels = [];
				var data = [];
				for (var i = 0; i < daysPrior; i++) {
					labels.push( dayjs().subtract(i, 'day').format('ddd') );
					data.push( daysAgo[i] == undefined ? 0 : daysAgo[i].length );
				}
				// today should be last entry
				labels = labels.reverse();
				data = data.reverse();

				// fill in the myChart
				const ctx = document.getElementById('myChart');
				// eslint-disable-next-line no-unused-vars
				const myChart = new Chart(ctx, {
				  type: 'bar',
				  data: {
					labels: labels,
					datasets: [{
					  data: data,
					  lineTension: 0,
					  backgroundColor: 'rgba(255, 159, 64, 0.9)',
					  borderColor: '#ffffff',
					  borderRadius: 25,
					  borderWidth: 1,
					  barThickness: 50,
					  pointBackgroundColor: '#007bff'
					}]
				  },
				  options: {
					plugins: {
					  legend: {
						display: false
					  },
					  tooltip: {
						boxPadding: 3
					  }
					}
				  }
				});
			}
		});
	}, 10000);
});

