$(document).ready(function() {

    $('.log').ajaxError(function() {
	$(this).text('ERROR: Shit has hit the fan for w/e reason...');
	$('form').find('button').removeAttr('disabled');
	$('form').find('button').text('Click me bitches');	
    });

$(".tab_content").hide(); 
	$("ul.tabs li:first").addClass("active").show(); 
	$(".tab_content:first").show(); 

	
	$("ul.tabs li").click(function() {

		$("ul.tabs li").removeClass("active"); 
		$(this).addClass("active"); 
		$(".tab_content").hide(); 

		var activeTab = $(this).find("a").attr("href"); 
		$(activeTab).fadeIn(); 
		return false;
	});

    $("form").submit(function(){
		
	$(this).find('button').attr('disabled', 'disabled');
	$(this).find('button').text('Processing...');
	 $.post("/new_form", $(this).serialize(), function(data){
//	     alert(data);
	     $('#alert').clone().appendTo('#notify_box').append('<p>Download:</p><a href="/download/' + data.filename + '">' + data.filename + '</a>').show('slow');

	     $('form').find('button').removeAttr('disabled');
	     $('form').find('button').text('Click me bitches');	
	     
	 });
	return false;
    });
    
});