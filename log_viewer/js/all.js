

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
					jQuery("#log_table").append("<tr><td>" + i + "</td><td>" + l[0] + " / " + l[1] + "</td><td>" + l[2] + "</td><td>" + txt + "</td></tr>");
				}
			}
		});
	}, 10000);
});

