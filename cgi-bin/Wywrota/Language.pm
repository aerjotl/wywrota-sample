package Wywrota::Language;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Exporter; 
use Wywrota::Config; 

our @ISA = qw(Exporter);
our @EXPORT = qw(plural msg);

my @months = ['', 'styczeń', 'luty', 'marzec', 'kwiecień', 'maj', 'czerwiec', 'lipiec', 'sierpień', 'wrzesień', 'październik', 'listopad', 'grudzień'];

sub msg {
# --------------------------------------------------------
# wstawia komunikat w odpowiednim języku
# usage: Wywrota::Language::msg('label')
	my $label = shift;
	my $cid = shift || $Wywrota::request->{content}{current}{id};
	my (%messages);
	
#	return "AAA $label $cid";
			
	%messages = (

		'set' => {
			0 => ['zestaw', 'set'],
			1 => ['zeszyt', 'notebook'],
			7 => ['śpiewnik', 'songbook'],
			10 => ['playlista', 'playlist'],
			16 => ['album', 'album']
		},
		'sets' => {
			0 => ['zestawy', 'sets'],
			1 => ['zeszyty', 'notebooks'],
			7 => ['śpiewniki', 'songbooks'],
			10 => ['playlisty', 'playlists'],
			16 => ['albumy', 'albums']
		},
		'set_title' => {
			0 => ['tytuł zestawu', 'set title'],
			1 => ['tytuł zeszytu', 'notebook title'],
			7 => ['tytuł śpiewnika', 'songbook title'],
			10 => ['tytuł playlisty', 'playlist title'],
			16 => ['tytuł albumu', 'album title']
		},
		'add_to_set' => {
			0 => ['do zestawu', 'add to set'],
			1 => ['do zeszytu', 'add to the notebook'],
			7 => ['do śpiewnika', 'add to the songbook'],
			16 => ['do albumu', 'add to the album']
		},			
		'remove_from_this_set' => {
			0 => ['usuń z tego zestawu', 'remove from this set'],
			1 => ['usuń z tego zeszytu', 'remove from this notebook'],
			7 => ['usuń z tego śpiewnika', 'remove from this songbook'],
			10 => ['usuń z tej playlisty', 'remove from this playlist'],
			16 => ['usuń z tego albumu', 'remove from this album']
		},			
		'already_in_set'		=> {
			0 => ['Ta pozycja już jest w tym zestawie.',
				  'This item is already present in this set.'],
			1 => ['Ten tekst już jest w tym zeszycie.',
				  'This text is already in this notebook.'],
			7 => ['Ta piosenka już jest w tym śpiewniku.',
				  'This song is already present in this songbook.'],
			10 => ['Ta piosenka już jest w tej playliście.',
				  'This song is already present in this playlist.'],
			16 => ['Ta praca już jest w tym albumie.',
				  'This work is already present in this album.'],
	   },
		'added_to_set'		=> {
			0 => ['Dodano do zestawu.',		'Added to the set.'],
			1 => ['Dodano do zeszytu.',		'Added to the notebook.'],
			7 => ['Dodano do śpiewnika.',	'Added to the songbook.'],
			10 => ['Dodano do playlisty.',	'Added to the playlist.'],
			16 => ['Dodano do albumu.',		'Added to the album.'],
	   },
	   
		'record_added'		=> {
			0 => ['Twoja pozycja została dodana.',		'Your item was added.'],
			1 => ['Twój tekst został zapisany',			'Your text was saved.'],
			3 => ['Twój artykuł został zapisany',		'Your article was saved.'],
			10 => ['Twój utwór został zapisany.',		'Your song was saved.'],
			16 => ['Twój obrazek został zapisany.',		'Your picture was saved.'],
	   },
	   	 

		'record_not_found'		=> {
			0 => ['Nie znalazłem wpisu.',			'Record not found.'],
			1 => ['Nie znalazłem tekstu.',			'Text not found.'],
			6 => ['Nie znalazłem takiej osoby w Aktach Wywroty. ',  'User not found.'],
			7 => ['Nie znalazłem utworu.',			'Lyrics not found.'],
			10 => ['Nie znalazłem nagrania.',		'Record not found.'],
			16 => ['Nie znalazłem pracy.',			'Artwork not found.']
	   },

		'already_in_favorites'		=> {
			0 => ['Ta pozycja już jest na twojej liście ulubionych.',
				  'This item is already present on your favorites list.'],
			1 => ['Ten tekst już jest na twojej liście ulubionych.',
				  'This text is already present on your favorites list.'],
			6 => ['Ten człowiek już jest na liście twoich znajomych.',
				  'This man is already present on your buddies list.'],
			7 => ['Ta piosenka już jest w twoich ulubionych.',
				  'This song is already present in your favorites.']
	   },
		'added_to_favorites'		=> {
			0 => ['Dodano do ulubionych.',
				  'Added to the favorites list.'],
			6 => ['Dodano do listy znajomych.',
				  'Added to buddies list.'],
			7 => ['Dodano do ulubionych piosenek.',
				  'Added to favorite songs.'],
			16 => ['Dodano do ulubionych prac.',
				  'Added to favorite works.'],
			15 => ['Dołączyłeś do fan klubu wykonawcy.',
				  'You have joined the fan-club of this artist.']
	   },

		'removed_from_favorites'		=> {
			0 => ['Usunięto z ulubionych.',
				  'Removed from the favorites list.'],
			6 => ['Usunięto z listy znajomych.',
				  'Removed from buddies list.'],
			7 => ['Usunięto z ulubionych piosenek.',
				  'Removed from favorite songs.'],
			16 => ['Usunięto z ulubionych prac.',
				  'Removed from favorite works.'],
			15 => ['Wypisano z fan klubu wykonawcy.',
				  'You have part the fan-club of this artist.']
	   },

				
		'replied_to'		=> {
			0 => ['dodał(a) komentarz do tekstu',
				  'added a comment to the text'],
			13 => ['wypowiedział się na forum w temacie',
				  'added a comment to the text'],
			16 => ['dodał(a) komentarz do pracy',
				  'added a comment to the text']
	   },

		'already_sent_for_contest'		=> {
			0 => ['Już wysłałeś pracę na ten konkurs!',
				  'You have already sent an artwork for this contest!'],
			1 => ['Już wysłałeś jeden tekst na ten konkurs!',
				  'You have already sent a text for this contest!'],
			3 => ['Już wysłałeś jeden artykuł na ten konkurs!',
				  'You have already sent an article for this contest!'],
	   },

		'send_for_contest'		=> {
			0 => ['Prześlij pracę na konkurs.',
				  'Send an artwork for contest.'],
			1 => ['Prześlij tekst na konkurs.',
				  'Send a text for contest.'],
			3 => ['Prześlij artykuł na konkurs.',
				  'Send a an article for contest.'],
	   },

		'addrecord'		=> {
			0 => ['Dodaj '.$Wywrota::request->{content}{current}{keyword},
				  'Submit '.$Wywrota::request->{content}{current}{keyword}],
			16 => ['Prześlij pracę',
				  'Submit artwork'],
			17 => ['Dodaj stronę',
				  'Add a page'],
			10 => ['Prześlij nagranie',
				  'Submit a record'],
			1 => ['Prześlij wiersz lub opowiadanie',
				  'Submit literature'],
			3 => ['prześlij newsa lub artykuł',
				  'Submit a news or an article '],
			12 => ['Załóż wspólnotę',
				  'Found a community'],
			15 => ['Dodaj nowego wykonawcę',
				  'Add a new band'],
				
			7 => ['prześlij tekst piosenki',
				  'submit lyrics']
	   },
		'favorites_list'		=> {
			0 => ['Ulubione',
				  'Favorites'],
			1 => ['Ulubione teksty',
				  'Favorite literature'],
			3 => ['Ulubione artykuły',
				  'Favorite articles'],
			6 => ['Znajomi',
				  'Buddies'],
			15 => ['Ulubione kapele i wykonawcy',
				  'Favorite bands and artists'],
			16 => ['Ulubione prace',
				  'Favorite works'],
			10 => ['Ulubione nagrania',
				  'Favorite records'],
			7 => ['Ulubione piosenki',
				  'Favorite songs'],
			23 => ['Ulubione zestawy',
				  'Favorite sets']
	   },
		'add_to_favorites'		=> {
			0 => ['Dodaj do ulubionych',
				  'Add to favorites'],
			6 => ['Do kontaktów',
				  'add to contact list'],
			7 => ['Dodaj do ulubionych',
				  'Add to Favorite Songs']
	   },

		'remove_from_favorites'		=> {
			0 => ['Usuń z ulubionych',
				  'Remove from favorites'],
			6 => ['Usuń z listy znajomych',
				  'remove from buddie list'],
			7 => ['Usuń z ulubionych',
				  'Remove from favorites']
	   },

				
		'no_favorites'		=> {
			0 => ['Nie masz żadnych ulubionych.',
				  'You dan\'t have any favorites.'],
			6 => ['Nie masz żadnych znajomych.',
				  'You don\'t have any buddies.'],
			16 => ['Nie masz żadnych ulubionych prac.',
				  'You dan\'t have any favorite works.'],
			7 => ['Nie masz żadnych ulubionych piosenek.',
				  'You don\'t have any songs in your songbook.']
	   },,
		'user_no_favorites'		=> {
			0 => ['Ten użytkownik nie ma żadnych ulubionych.',
				  'This user do not have any favorites.'],
			6 => ['Użytkownik nie ma żadnych znajomych na Wywrocie.',
				  'User do not have any buddies on Subverse.'],
			12 => ['Nie zapisany do żadnej wspólnoty.',
				  'Not a member of any comunity.']
	   },

		'favorites_users'		=> {
			0 => ['Zaznaczyli jako ulubione',
				  'Marked as favorite'],
			12 => ['Członkowie społeczności',
				  'Society members'],
			15 => ['Członkowie fan klubu',
				  'Fan-club members']
	   },

		'rank_this_item'		=> {
			0 => ['Oceń ten tekst',
				  'Rank this text'],
			10 => ['Oceń to nagranie',
				  'Rank this recotd'],
			16 => ['Oceń tę pracę',
				  'Rank this artwork']
	   },

		'this_item'		=> {
			0 => ['ten tekst',
				  'this text'],
			1 => ['ten tekst',
				  'this text'],
			10 => ['to nagranie',
				  'this record'],
			16 => ['tę pracę',
				  'this artwork']
	   },

		'your_item'		=> {
			0 => ['twój tekst',
				  'your text'],
			10 => ['twoje nagranie',
				  'your recotd'],
			16 => ['twoja praca',
				  'your artwork']
	   },

		'other_items'		=> {
			0 => ['inne teksty autora',
				  'more of this author'],
			7 => ['inne utwory wykonawcy',
				  'more of this band'],
			10 => ['inne nagrania autora',
				  'more of this author'],
			16 => ['inne prace autora',
				  'more of this author']
	   },

		'top_records'		=> {
			0 => ['najpopularniejsze teksty',
				  'top texts'],
			7 => ['najpopularniejsze utwory',
				  'top songs'],
			10 => ['najpopularniejsze nagrania',
				  'top records'],
			15 => ['najpopularniejsi wykonawcy',
				  'top bands'],
			16 => ['najpopularniejsze',
				  'top artworks']
	   },


		'track_comments'		=> {
			0 => ['powiadom mnie o nowych komentarzach',
				'notify me about new comments'],
			#1 => ['śledź komentarze do tego tekstu',
			#	'track this text comments'],
			#7 => ['śledź komentarze do tej piosenki',
			#	'track this song comments'],
			#10 => ['śledź komentarze do tego utworu',
			#	'track this song comments'],
			12 => ['powiadom mnie o nowych tematach',
				'notify me about new topics'],
			13 => ['powiadom mnie o nowych wiadomościach w tym wątku',
				'notify me about new posts in this thread'],
			#16 => ['śledź komentarze do tej pracy',
			#	'track this artwork comments']			
	   },


		'stop_tracking_comments'		=> {
			0 => ['(wyłącz)',
				'don\'t notify me'],
			#1 => ['nie śledź komentarzy do tego tekstu',
			#	'track this text comments'],
			#7 => ['nie śledź komentarzy do tej piosenki',
			#	'track this song comments'],
			#10 => ['nie śledź komentarzy do tego utworu',
			#	'track this song comments'],
			12 => ['(wyłącz)',
				'don\'t notify me about new topics'],
			13 => ['(wyłącz)',
				'don\'t notify me about thread'],
			#16 => ['nie śledź komentarzy do tej pracy',
			#	'track this artwork comments']			
	   },




	);
			
	%words = (
		'wywrota'		=> ['wywrota',		'subverse'],
		'subverse'		=> ['wywrota',		'subverse'],
		'my_subverse'	=> ['Moja Wywrota',	'My Subverse'],
		'logout'		=> ['wyloguj',		'log out'],
		'log_in'			=> ['Zaloguj się',	'Log in'],
		'log_in_and_connect'=> ['Zaloguj się i połącz',	'Log in & Connect'],
		'facebook_login'=> ['Zaloguj się przez Facebooka',	'Facebook Log in'],
		'facebook_register'=> ['Zarejestruj się przez Facebooka',	'Register via Facebook'],
		'register'		=> ['Zarejestruj się',	'Register'],
		'password'		=> ['hasło',		'password'],
		'wywrota_komuna'=> ['Wywrota - komuna internetowa',		'Subverse - internet commune'],
		'subversive_lyrics' => ['Wywrotowy Śpiewnik',		'Subversive lyrics'],

		'literature'		=> ['Literatura',	'Literature'],
		'music'				=> ['Muzyka',		'Music'],
		'culture'			=> ['Kultura',		'Culture'],
		'art'				=> ['Sztuka',		'Art'],
		'gallery'			=> ['Galeria',		'Gallery'],
		'theater'			=> ['Teatr',		'Theater'],
		'cinema'			=> ['Kino',			'Cinema'],
		'movie'				=> ['Film',			'Movie'],

		'forum'				=> ['Forum',		'Forum'],
		'songbook'			=> ['Śpiewnik',		'Songbook'],
		'integration'		=> ['Integracja',	'Integration'],
		'society'			=> ['Społeczność',	'Society'],
		'image_file_120'	=> ['obrazek o szerokości&nbsp;120px',	'image 120px width'],
		'group_members'		=> ['członkowie grupy',	'group members'],
		'recommend'			=> ['polecany',	'recommended'],

		'you_dont_have_account'	=> [
			'Nie masz konta?',	
			'You don\'t have an account?'],
		'forgotten_password' => [
			'Zapomniałeś hasła?',	
			'Forgotten password?'],
		'store_password' => [
			'zapamiętaj mnie',	
			'remember me'],

		'no_search_query' => [
			'Nie zadałeś pytania wyszukiwarce',
			'You did not ask any query'],

		'empty_query' => [
			'Pusty zbiór wyników',
			'Empty result set'],

		'forum_missing_arguments'=> [
			'Aby założyć nowy temat kliknij odpowiednią ikonę.',
			'To start a new thread click a proper icon.'],

		'create_group'	=> ['Załóż grupę',		'Create group'],
		'joined_group'	=> ['Dołączyłeś do tej grupy',		'You have joined this group'],
		'left_group'	=> ['Wypisałeś się z tej grupy',		'You have left this group'],
		
		'add'			=> ['dodaj',		'add'],
		'remove'		=> ['usuń',			'remove'],
		'modify'		=> ['edytuj',		'modify'],
		'search'		=> ['szukaj',		'search'],
		'searchin'		=> ['wyszukaj',		'search'],			
		'find'			=> ['Znajdź',		'Find'],			
		'favorites'		=> ['ulubione',		'favorites'],
		'send'			=> ['prześlij',		'send'],
		'join'			=> ['dołącz',		'join'],
		'leave'			=> ['wypisz się',	'leave'],
		'page_layout'	=> ['układ strony',	'page layout'],
		'color'			=> ['kolor',		'color'],
		'page_title'	=> ['tytuł strony',		'page title'],
		'menu_title'	=> ['tytuł w menu',		'menu title'],
		'keywords'		=> ['słowa kluczowe',	'keywords'],
		'details'		=> ['szczegóły',	'details'],
		'meta'			=> ['meta',	'meta'],
		'page_content'	=> ['treść strony',	'page content'],
		'moderation'	=> ['moderacja',	'moderation'],
		'content'		=> ['treść',		'content'],
		'notifications'	=> ['powiadomienia',	'notifications'],
		'flag'			=> ['zgłoś',	'flag'],
		'send_link'		=> ['wyślij znajomemu',	'send link'],
		'who_can_vote'	=> ['kto może głosować',	'who can vote'],
		'who_can_comment'=> ['kto może komentować',	'who can comment'],
		'add_to_community'=> ['dodaj do grupy',	'add to community'],
		

			



			
			
		'shop'			=> ['sklepik',		'shop'],
		'whats_new'		=> ['co nowego?',	'what\'s new?'],
		'advertisement'	=> ['reklama',		'advertisement'],
		'patronate'		=> ['patronat',		'auspices'],
		'description'	=> ['opis',			'description'],
			
		'reply'			=> ['odpowiedź',	'reply'],
		'pages'			=> ['strony',		'pages'],

		'auspices'		=> ['patronat',		'auspices'],
		'introduction'	=> ['zajawka',		'introduction'],		

		'members'		=> ['członkowie',	'members'],		
		'fans'			=> ['fani',			'fans'],		
		'new_members'	=> ['Nowi członkowie',	'New members'],		
		'of_this_author'=> ['tego autora',	'of this author'],		
		'gallery'		=> ['Galeria',	'Gallery'],		
		'contest'		=> ['konkurs',	'contest'],
		'join_group'	=> ['dołącz do grupy',	'join the group'],
		'leave_group'	=> ['opuść grupę',	'leave the group'],
		'already_member'=> ['już jesteś członkiem tej grupy',	'you are a member of this group already'],
		'remove_from_community'=> ['usuń z grupy',	'remove from community'],
		
		'limit_val'		=> ['limit',	'limit'],
		

		'add_artists_photo'		=> [
			'prześlij zdjęcie wykonawcy',	
			'add artist\'s photo'],		
		'notify_me_about_this_thread' => [
			'powiadom mnie o odpowiedziach',
			'notify me about the answers'],		
	

		
		'awaiting_auth'		=> [ 'czekające na autoryzację',				'awaiting authorisation'],		
		'moderate_state_1'	=> [ 'czeka na autoryzację',				'awaiting authorisation'],		
		'moderate_state_2'	=> [ 'autoryzowany',						'authorised'],		
		'moderate_state_3'	=> [ 'nie uzyskał autoryzacji Wywroty',		'did not get Subverse authorisation'],		
		'moderate_state_4'	=> [ 'bez autoryzacji Wywroty',				'no Subverse authorisation'],		
		'moderate_state_5'	=> [ 'zaimportowany',				'imported'],		


		'distinction_confirm_1'	=> [ 'polecono',				'distinction confirmed'],		
		'distinction_confirm_2'	=> [ 'nadano wyróżnienie',		'distinction confirmed'],		
		'distinction_confirm_3'	=> [ 'wyróżnieniono jako pracę miesiąca',		'distinction confirmed'],		

		'songs_in_songbook'	=> ['Piosenki w śpiewniku',	'Songs in songbook'],		


		'topic'			=> ['temat',		'topic'],		
		'author'		=> ['autor',		'author'],		
		'rep'			=> ['odp.',			'rep.'],		
		'last_entry'	=> ['ostatni wpis',	'last entry'],		
		'new_topic'		=> ['nowa dyskusja',	'new topic'],		
		'reply'			=> ['odpowiedz',	'reply'],		
		'name'			=> ['nazwa',	'name'],		
		'read'			=> ['czytaj',	'read'],		
		'turn_off_ad'	=> ['wyłącz reklamy',	'turn off advertisements'],		
		'visibility'	=> ['widoczność',	'visibility'],	
		'review'		=> ['moderacja',	'review'],	
		'limit_per'		=> ['w czasie',	'limit per'],	

			
		


		'privacy' 		=> ['prywatność', 'privacy'],
		'select'		=> ['wybierz ', 'select a '],
		'new' 		=> ['nowy ', 'new '],
		'file' 		=> ['plik', 'file'],
			
		'create_new' 		=> ['Utwórz nowy ', 'Create new '],
		'find_group' 		=> ['Znajdź grupę ', 'Find group'],
		'browse_groups' 	=> ['Przeglądaj grupy', 'Browse groups'],		


		'found'			=> ['Znalazłem',	'Found'],		
		'not_found_any'	=> ['Nie znalazłem żadnych',	'Not found any'],		
			


			 

		# Songbook
			
		'in_songbook_you_will_find'	=> [
			'W naszym śpiewniku znajdziesz',	
			'In our songbook you\'ll find'],		

		'in_songbook_you_will_find'	=> [
			'W naszym śpiewniku znajdziesz',	
			'In our songbook you\'ll find'],		

		'of_this_artist'	=> [
			'tego wykonawcy',	
			'of this artist'],


		'lyrics'		=> ['tekst',			'lyrics'],
		'song_lyrics'	=> ['tekst utworu',	'lyrics'],
		'chords'		=> ['chwyty',			'chords'],
		'chords_separated'		=> ['chwyty (rozdzielone przecinkami)',			'chords (separated by comma)'],
		'guitar_chords'	=> ['chwyty na gitarę',	'guitar chords'],
		'tabulature'	=> ['tabulatura',		'tabulature'],
		'movie_clip'	=> ['teledysk',			'movie clip'],
		'youtube'		=> ['link do YouTube',			'Youtube link'],

		
		'no_lyrics'		=> ['brak tekstu',		'no lyrics'],
		'no_chords'		=> ['brak chwytów',		'no chords'],
		'no_tabulature'	=> ['brak tabulatury',	'no tabulature'],
		'album'			=> ['album',			'album'],
		'lyrics_author'		=> ['słowa (autor)',			'lyrics (author)'],
		'music_author'		=> ['muzyka (autor)',			'music (author)'],
		
		'image'		=> ['obrazek',				'image'],
		'photo'		=> ['zdjęcie',				'photo'],

		


		# Login / permissions stuff

		'wrong_password_msg' => [
			'Podałeś zły WywrotID lub hasło. Spróbuj jeszcze raz.',		
			'You have entered invalid login and password. Please try again.'],
		'action_require_logged_in_msg' => [
			'Musisz być zalogowany, aby wykonać tą akcję.',		
			'You need to be logged in to perform this action.'],
		'log_in_to_vote' => [
			'Zaloguj się aby głosować.',		
			'Log in to vote.'],
		'log_in_fav' => [
			'Zaloguj się, aby mieć możliwość edycji ulubionych.',		
			'Log in to edit favorites.'],
		'no_permissions' => [
			'Nie masz uprawnień',		
			'You don\'t have permissions'],
		'no_permissions_msg' => [
			'Nie masz odpowiednich uprawnień, aby wykonać tą akcję!',
			'You don\'t have permissions to perform this action!'],
		'no_permissions_forum' => [
			'Nie masz odpowiednich uprawnień aby zobaczyć to forum.<br>Aby uzyskać dostęp skontaktuj się z moderatorem: ',
			'You don\'t have permissions to see this forum<br>Go teg access contact moderator: '],



		'buy_tshirt' => [
			'kup koszulkę!',
			'buy a T-Shirt!'],


		'anonymous_publication' => [
			'anonimowa publikacja',
			'anonymous_publication'],

		'anonymous' => [
			'anonimowość',
			'anonymous'],

		'anonymous_period' => [
			'ukrywaj moje dane przez&nbsp;okres',
			'hide my data for'],

		'anonymous_nick' => [
			'pseudonim',
			'anonymous nick'],

		'anonymous_user' => [
			'autor pozostaje anonimowy',
			'author is anonymous'],

		'method_of_publication' => [
			'metoda publikacji',
			'method of publication'],

		'friends_activity' => [
			'aktywność znajomych',
			'friends activity'],

		'group_activity' => [
			'aktywność w grupach',
			'group activity'],

			

		'quick_answer' => [
			'szybka odpowiedź:',
			'quick answer:'],

		'started_tracking' => [
			'powiadomienia włączone',
			'started tracking comments'],

		'stopped_tracking' => [
			'wyłączono powiadomienia',
			'stopped tracking comments'],

		'all_rights_reserved' => [
			'Wszelkie prawa zastrzeżone',
			'All rights reserved'],


		'featured' => [
			'wyróżnienie',
			'featured'],

		'featured_on_hp' => [
			'wyróżnij na stronie głównej',
			'featured on the home page'],

		'target_address_url' => [
			'adres docelowy url',
			'target address url'],

		'title' => [
			'tytuł',
			'title'],

		'article_title' => [
			'tytuł artykułu',
			'article title'],

		'lyrics_title' => [
			'tytuł utworu',
			'lyrics title'],

		'article_reference' => [
			'artysta, wykonawca, tytuł filmu, książki itp.',
			'referecne'],

		'article_tags' => [
			'tagi (oddzielone przecinkami)',
			'tags (separated by commas)'
		],
			
		'nothing_found' => [
			'nic nie znaleziono',
			'nothing found'],

		'promoted_artist' => [
			'Wywrota poleca',
			'promoted artist'],

		'language' => [
			'język',
			'language'],

		'source' => [
			'źródło',
			'source'],

		'print' => [
			'drukuj',
			'print'],

		'show_photo_list' => [
			'pokaż listę zdjęć',
			'show photo list'],

		'account_deleted' => [
			'konto usunięte',
			'account deleted'],

		'my_account' => [
			'moje konto',
			'my account'],
		
		'deleted' => [
			'usunięto',
			'deleted'],
		
		'no_forum_topics' => [
			'brak wpisów na forum tego wykonawcy',
			'no entries on this band forum'],
		

		'save_paper' => [
			'<b>Oszczędzaj papier.</b><br>Pomyśl zanim wydrukujesz!',
			'<b>Save paper.</b><br>Think before you print!'],

		'page_no_parent' => [
			'Nie wybrano rodzica strony. Przy dodawaniu lepiej korzystaj z mapy strony.',
			'No page parent selected.'],
		
		'send_to_group' => [
			'wyślij do grupy',
			'send to group'],

		'action_or_pagefilename' => [
			'akcja lub nazwa pliku do dołączenia',
			'action or page filename'],
			


		'author' 				=> ['autor',				'author'],		
		'groups' 				=> ['grupy',				'groups'],		
		'publication_details' 	=> ['szczegóły publikacji', 'publication details'],
		'what_is_subverse' 		=> ['co to jest wywrota?', 	'what is subverse?'],
		'contact_us' 			=> ['kontakt', 				'contact us'],
		'sitemap' 				=> ['mapa serwisu', 		'site map'],
		'terms_of_service' 		=> ['regulamin', 			'terms of service'],
		'friends' 				=> [ 'przyjaciele', 		'friends'],
		'links' 				=> [ 'linki', 				'links'],
		'editorial_staff' 		=> [ 'redakcja', 			'editorial staff'],

		'date_from' => [ 'data od', 'date from'],
		'date_to' => [ 'data do', 'date to'],
		'city' 		=> ['miasto',				'city'],		
		'location' => [ 'miejsce', 'location'],
		'content_type' => [ 'rodzaj tekstu', 'content type'],
		'category' => [ 'kategoria', 'category'],
		'pages'			=> ['strony',		'pages'],
		'award_date'	=> ['data przyznania',		'award date'],
		'prize_info'	=> ['informacje o nagrodzie',		'prize info'],
		'sent_date'		=> ['data wysłania',		'sent date'],
		'sql_error'		=> ['Błąd w wykonaniu zapytania SQL',	'Error executing SQL query'],

		'def_photo_changed'		=> ['Zmieniono główne zdjęcie',	'changed the default photo'],
		'def_photo_not_changed'		=> ['Nie udało się zmienić domyślnego zdjęcia',	'couldn\'t change the default photo'],

		'video_added'		=> ['dodano film',		'video added'],
		'chords_added'		=> ['dodano akordy',	'chords added'],

		'can_comment'		=> ['opinie',	'opinions'],
		'can_vote'			=> [' ',	' '],
		'html_snippet'		=> ['dodatkowy kod html',	'html snippet'],
		'user_id'			=> ['id użytkownika',	'user id'],





	);
	
	
	#if ($Wywrota::request->{language}{id} == 1) {
	return eval {
	
		if (defined($messages{$label})) {
			if ( defined($messages{$label}{$cid}) ) {
				return $messages{$label}{$cid}[0];
			} else {
				return $messages{$label}{0}[0];
			}
		} elsif (defined($words{$label}[0])) {
			return $words{$label}[0];
		}
	};
		
	#} else {
	#	if (defined($messages{$label})) {
	#		if ( defined($messages{$label}{$cid}) ) {
	#			return $messages{$label}{$cid}[1];
	#		} else {
	#			return $messages{$label}{0}[1];
	#		}
	#	} elsif (defined($words{$label}[1])) {
	#		return $words{$label}[1];
	#	} 
	#}   
	return qq~$label~;
}

sub plural {
# --------------------------------------------------------
# wstawia rzeczownik w odpowiedniej formie
	my ($liczba, $wyraz, $mianownik) = @_;
	my ($tmp, %gram);
			
	# 'l.p. mianownik' => ['l.p. biernik', 'l.m. mianownik', 'l.m. dopelniacz']
	%gram = (
		'rok' => ['rok', 'lata', 'lat'],
		'miesiąc' => ['miesiąc', 'miesiące', 'miesięcy'],
		'dzień' => ['dzień', 'dni', 'dni'],
		'sekunda' => ['sekundę', 'sekundy', 'sekund'],
		'wpis' => ['wpis', 'wpisy', 'wpisów'],
		'tekst' => ['tekst', 'teksty', 'tekstów'],
		'strona' => ['stronę', 'strony', 'stron'],
		'praca' => ['pracę', 'prace', 'prac'],
		'rok' => ['rok', 'lata', 'lat'],
		'data' => ['datę', 'daty', 'dat'],
		'adres' => ['adres', 'adresy', 'adresów'],
		'głos' => ['głos', 'głosy', 'głosów'],
		'komentarz' => ['komentarz', 'komentarze', 'komentarzy'],
		'człowiek' => ['człowieka', 'ludzi', 'ludzi'],
		'członek' => ['członek', 'członków', 'członków'],
		'fan' 	=> ['fan', 'fanów', 'fanów'],
		'czlowiek' => ['człowieka', 'ludzi', 'ludzi'],
		'osoba' => ['osoba', 'osoby', 'osób'],
		'artykuł' => ['artykuł', 'artykuły', 'artykułów'],
		'artykul' => ['artykuł', 'artykuły', 'artykułów'],
		'news' => ['news', 'newsy', 'newsów'],
		'zaimportowany news' => ['zaimportowany news', 'zaimportowane newsy', 'zaimportowanych newsów'],
		'utwór' => ['utwór', 'utwory', 'utworów'],
		'piosenka' => ['tekst piosenki', 'piosenki', 'piosenek'],
		'tekst piosenki' => ['tekst piosenki', 'teksty piosenek', 'tekstów piosenek'],
		'zdjęcie' => ['zdjęcie', 'zdjęcia', 'zdjęć'],
		'wiersz' => ['wiersz', 'wiersze', 'wierszy'],
		'flaga' => ['flagę', 'flagi', 'flag'],
		'news' => ['newsa', 'newsy', 'newsów'],
		'opowiadanie' => ['opowiadanie', 'opowiadania', 'opowiadań'],
		'dramat' => ['dramat', 'dramaty', 'dramatów'],
		'wiersz klasyka' => ['wiersz klasyka', 'wiersze klasyków', 'wierszy klasyków'],
		'nowy link' => ['nowy link','nowe linki','nowych linków'],
		'podcast' => ['podcast','podcasty','podcastów'],
		'cytat' => ['cytat','cytaty','cytatów'],
		'kategoria' => ['kategorię','kategorie','kategorii'],
		'społeczność' => ['społeczność','społeczności','społeczności'],
		'wspólnota' => ['wspólnotę','wspólnoty','wspólnot'],
		'zdjecie' => ['zdjęcie','zdjęcia','zdjęć'],
		'post' => ['post','posty','postów'],
		'akta' => ['dane w aktach','akt','akt'],
		'czlonek' => ['członek','członków','członków'],
		'odpowiedź' => ['odpowiedź','odpowiedzi','odpowiedzi'],
		'wykonawca' => ['wykonawcę','wykonawców','wykonawców'],
		'praca graficzna' => ['pracę graficzną','prace','prac'],
		'praca' => ['pracę','prace','prac'],
		'nagranie' => ['nagranie','nagrania','nagrań'],
		'kanał' => ['kanał','kanały','kanałów'],		
		'film' => ['film','filmy','filmów'],		
		'zestaw wierszy' => ['zestaw wierszy','zestawy wierszy','zestawów wierszy'],		
		'zestaw' => ['zestaw','zestawy','zestawów'],		
		'zeszyt' => ['zeszyt','zeszyty','zeszytów'],		
		'śpiewnik' => ['śpiewnik','śpiewniki','śpiewników'],		
		'album' => ['album','albumy','albumów'],		
		'pozycja' => ['pozycję','pozycje','pozycji'],		
		'grupa' => ['grupę','grupy','grup'],		
		'oczekuje' => ['oczekuje','oczekują','oczekuje'],		
		'nowy' => ['nowy','nowe','nowych'],		
		'zgłoszenie' => ['zgłoszenie','zgłoszenia','zgłoszeń'],		
		'wydarzenie' => ['wydarzenie','wydarzenia','wydarzeń'],		
		'wyświetlenie' => ['wyświetlenie','wyświetlenia','wyświetleń'],		
		
		

	);
	$liczba = $liczba%100 if $liczba>100;
	$tmp = $liczba%10;
	if ($liczba == 1) {
		return ($mianownik) ? $wyraz : $gram{$wyraz}[0];
	}
	elsif (($liczba>4) and ($liczba<21)) {
		return $gram{$wyraz}[2];
	}
	elsif (($tmp > 1) && ($tmp < 5)) {
		return $gram{$wyraz}[1];
	}
	else {return $gram{$wyraz}[2];}   
}

sub month_name {
	return $months[shift];
}


1;
