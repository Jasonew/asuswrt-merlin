﻿<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<html xmlns:v>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title><#Web_Title#> - QoS Statistics</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="usp_style.css">
<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/chart.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script>

var qos_type ="<% nvram_get("qos_type"); %>";
var value1K = 1000;

if ("<% nvram_get("qos_enable"); %>" == 0) {	// QoS disabled
	var qos_mode = 0;
}else if (qos_type == "1") {			// aQoS - not supported
	var qos_mode = 0;
} else if (qos_type == "0") {			// tQoS
	var qos_mode = 1;
} else if (qos_type == "2") {			// BW limiter
	var qos_mode = 3;
} else {					// invalid mode
	var qos_mode = 0;
}


var category_title = ["", "Highest", "High", "Medium", "Low", "Lowest"];
var color = ["#B3645B","#B98F53","#C6B36A","#849E75","#2B6692","#7C637A","#4C8FC0", "#6C604F"];

<% get_tcclass_array(); %>

var pieOptions = {
        segmentShowStroke : false,
        segmentStrokeColor : "#000",
        animationEasing : "easeOutQuart",
        animationSteps : 100,
        animateScale : true,
	legend : { display : false },
	tooltips: {
		callbacks: {
			title: function (tooltipItem, data) { return data.labels[tooltipItem[0].index]; },
			label: function (tooltipItem, data) {
				var value = data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index];
				var orivalue = value;
				var total = eval(data.datasets[tooltipItem.datasetIndex].data.join("+"));
				var unit = " bytes";
				if (value > value1K) {
					value = (value / value1K );
					unit = " KB";
				}
				if (value > value1K) {
					value = (value / value1K );
					unit = " MB";
				}
				if (value > value1K) {
					value = (value / value1K );
					unit = " GB";
				}
				return value.toFixed(2) + unit + ' ( ' + parseFloat(orivalue * 100 / total).toFixed(2) + '% )';

			},
		}
	},

}

function comma(n){
	n = '' + n;
	var p = n;
	while ((n = n.replace(/(\d+)(\d{3})/g, '$1,$2')) != p) p = n;
	return n;
}

function initial(){
	var code;

	show_menu();

	switch (qos_mode) {
		case 0:		// Disabled
			document.getElementById('dl_tr').style.display = "none";
			document.getElementById('ul_tr').style.display = "none";
			document.getElementById('no_qos_notice').style.display = "";
			return;

		case 3:		// Bandwith Limiter
			document.getElementById('dl_tr').style.display = "none";
			document.getElementById('ul_tr').style.display = "none";
			document.getElementById('limiter_notice').style.display = "";
			return;

		case 1:         // Traditional
			document.getElementById('dl_tr').style.display = "";
			document.getElementById('ul_tr').style.display = "";

			var ctx_dl = document.getElementById("pie_chart_dl").getContext("2d");
			tcdata_lan_array.sort(function(a,b) {return a[0]-b[0]} );
			code = setup_data(tcdata_lan_array, ctx_dl);
			document.getElementById('legend_dl').innerHTML = code;

			var ctx_ul = document.getElementById("pie_chart_ul").getContext("2d");
			tcdata_wan_array.sort(function(a,b) {return a[0]-b[0]} );
			code = setup_data(tcdata_wan_array, ctx_ul);
			document.getElementById('legend_ul').innerHTML = code;
			break;

		case 2:		// Adaptive - not supported
			break;
	}
}

function setup_data(data_array, ctx) {
	var code = '<table><thead style="text-align:left;"><tr><th style="padding-left:5px;">Class</th><th style="padding-left:5px;">Total</th><th style="padding-left:20px;">Rate</th><th style="padding-left:20px;">Packet rate</th></tr></thead>';
	var values_array = [];
	var labels_array = [];

	for (i=0; i < data_array.length-1; i++){
		var value = parseInt(data_array[i][1]);
		var tcclass = parseInt(data_array[i][0]);
		var rate;

		tcclass = tcclass / 10;
		var label = category_title[tcclass];
		if (label == undefined) {
			label = "Class " + tcclass;
		}

		labels_array.push(label);
		values_array.push(value);

		var unit = " Bytes";
		if (value > value1K) {
			value = (value / value1K );
			unit = " KB";
		}
		if (value > value1K) {
			value = (value / value1K );
			unit = " MB";
		}
		if (value > value1K) {
			value = (value / value1K );
			unit = " GB";
		}

		code += '<tr><td style="word-wrap:break-word;padding-left:5px;padding-right:5px;background-color:'+color[i]+';margin-right:10px;line-height:20px;">' + label + '</td>';
		code += '<td style="padding-left:5px;">' + value.toFixed(2) + unit + '</td>';
		rate = comma(data_array[i][2]);
		code += '<td style="padding-left:20px;">' + rate.replace(/([0-9,])([a-zA-Z])/g, '$1 $2') + '</td>';
		rate = comma(data_array[i][3]);
		code += '<td style="padding-left:20px;">' + rate.replace(/([0-9,])([a-zA-Z])/g, '$1 $2') + '</td></tr>';
	}
	code += '</table>';

	var pieData = {labels: labels_array,
		datasets: [
			{data: values_array,
			backgroundColor: color,
			hoverBackgroundColor: color,
			borderColor: "#444",
			borderWidth: "1"
		}]
	};

	var pie_obj = new Chart(ctx,{
	    type: 'pie',
	    data: pieData,
	    options: pieOptions
	});
	return code;
}

function resetCounters() {
	document.form.action_script.value = "resetqosstats";
	document.form.action_wait.value="2";
	showLoading();
	document.form.submit();

}

</script>
</head>
<body onload="initial();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="current_page" value="QoS_Stats.asp">
<input type="hidden" name="next_page" value="QoS_Stats.asp">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="action_wait" value="5">
<input type="hidden" name="flag" value="">

<table class="content" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <td width="17">&nbsp;</td>
    <td valign="top" width="202">
      <div id="mainMenu"></div>
      <div id="subMenu"></div></td>
    <td valign="top">
        <div id="tabMenu" class="submenuBlock"></div>

      <!--===================================Beginning of Main Content===========================================-->
      <table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
        <tr>
          <td valign="top">
            <table width="760px" border="0" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
                <tbody>
                <tr bgcolor="#4D595D">
                <td valign="top">
	                <div>&nbsp;</div>
		        <div class="formfonttitle">QoS - Traffic Classification Statistics</div>
		        <div style="margin-left:5px;margin-top:10px;margin-bottom:10px"><img src="/images/New_ui/export/line_export.png"></div>
			<div id="limiter_notice" style="display:none;font-size:125%;color:#FFCC00;">Statistics not available in Bandwidth Limiter mode.</div>
			<div id="no_qos_notice" style="display:none;font-size:125%;color:#FFCC00;">QoS is not enabled.</div>
			<table>
				<tr id="dl_tr">
					<td style="padding-left:50px;padding-right:50px;font-size:125%;color:#FFCC00;"><div>Download</div><canvas id="pie_chart_dl" width="200" height="200"></canvas></td>
					<td><span id="legend_dl"></span></td>
				</tr>
				<tr style="height:50px;"><td colspan="2">&nbsp;</td></tr>
                                <tr id="ul_tr">
                                        <td style="padding-left:50px;padding-right:50px;font-size:125%;color:#FFCC00;"><div>Upload</div><canvas id="pie_chart_ul" width="200" height="200"></canvas></td>
                                        <td><span id="legend_ul"></span></td>
                                </tr>
			</table>
			<div class="apply_gen" style="padding-top: 25px;">
				<input type="button" class="button_gen" value="<#CTL_refresh#>" onClick="location.href=location.href">
				<input type="button" id="resetButton" class="button_gen" value="Reset" onclick="resetCounters();">
			</div>
		</td>
		</tr>
	        </tbody>
            </table>
            </td>
       </tr>
      </table>
      <!--===================================Ending of Main Content===========================================-->
    </td>
    <td width="10" align="center" valign="top">&nbsp;</td>
  </tr>
</table>
</form>
<div id="footer"></div>
</body>
</html>
