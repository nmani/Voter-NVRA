$(document).ready(function() {

    $('.log').ajaxError(function() {
	$(this).text('ERROR: Shit has hit the fan for w/e reason...');
	$('form').find('button').removeAttr('disabled');
	$('form').find('button').text('Click me bitches');	
    });

    $("form").submit(function(){
	//$("div.content").fadeOut('slow');
	// $("div.verify").click(function(){
	//     $("div.content").slideToggle('slow');
	// });
	$(this).find('button').attr('disabled', 'disabled');
	$(this).find('button').text('Processing...');
	 $.post("/new_form", $(this).serialize(), function(data){
	     $('#alert').clone().appendTo('#notify_box').append('<p>Download:</p><a href="/download/' + data.filename + '">' + data.filename + '</a>').show('slow');

	     $('form').find('button').removeAttr('disabled');
	     $('form').find('button').text('Click me bitches');	
	     
	 });
	return false;
    });
    
});