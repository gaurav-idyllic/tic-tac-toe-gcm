$('td.tick_item_class').click(function(){
  var game_id = $('.game_id_cls').val(),
      is_game_finished = $('.is_game_finished_class').val();
  if(is_game_finished == 'true') {
    toastr.error('Move not allowed, game is already over.');
    return false;
  }
  var self = $(this);
  if(self.attr('disabled') == 'disabled') {
    toastr.error('move already taken.');
    return false;
  }

  $.ajax({
      url: "/games/" +game_id+ "/move_by_player",
      type: 'PUT',
      data: {
        move: self.attr("id")
      }
    })
    .done(function(response) {
      if(response.success){
        // self.css("background-color", "red");
        self.text('X');
        self.attr('disabled', true);
        if(response.user_win) {
          toastr.success('Player won the match.');
          $('.is_game_finished_class').val('true');
        } else if(response.system_win) {
          toastr.success('System won the match.');
          $('.is_game_finished_class').val('true');
        } else if(response.tie) {
          toastr.warning('Match DRAW.');
          $('.is_game_finished_class').val('true');
        }
        if(response.system_move.length > 0 && !response.user_win) {
          system_item = $("#tick_"+response.system_move[0]+"_"+response.system_move[1]);
          $(system_item).text('O');
          $(system_item).attr('disabled', true);
        }
      } else {
        toastr.error(response.errors);
      }
    })
    .fail(function() {
      toastr.error(response.errors);
    });
});
