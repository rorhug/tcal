Tcal
====


####Contents

- [About](#about)
- [How it worked](#how-it-worked)
- [Trello Board](#trello-board)
- [Source code overview](#source-code-overview)
- [Misc technical details](#misc-technical-details)

## About

[Tcal](https://tcal.rory.ie/) was something I made for students in [TCD](https://www.tcd.ie/) to sync their timetable into Google Calendar.

**If you are just looking for a method that currently works, click [HERE!](https://tcal.rory.ie/ics/)**

It no longer exists since it asked students for their [SITS (student portal)](https://my.tcd.ie) password. Storing passwords in an encrypted yet recoverable format is not something I learned was considered "bad" after launching it. I considered a few alternative options while ideating but chose to use this method as it was the best way I could achieve a seamless experience.

I just wanted to build something cool, by myself and without jumping through the bureaucratic hoops of which tcd is home to.

For a growing number of students it made it possible to sign up and successfully, never need to return. They could use the pre-installed and convenient Apple/Google calendar apps instead of one of the universities many attempts at web pages and proprietary apps.

<img src="images/gcal-tcal.png" width="564" alt="exam event details in mac calendar">

#### How I got caught! 
TODO how I was caught/why you should use a VPN in college

#### UT Story

- 2017-12-08 [College Shuts Down Popular Trinity Calendar Service](http://www.universitytimes.ie/2017/12/college-shuts-down-popular-trinity-calendar-service/)
- 2017-12-10 [Tcal Shutdown at Odds With Trinity’s Fostering of Entrepreneurship](http://www.universitytimes.ie/2017/12/tcal-shutdown-at-odds-with-trinitys-fostering-of-entrepreneurship/)
- 2017-12-13 [Tcal Risked Student Data, Says College](http://www.universitytimes.ie/2017/12/tcal-risked-student-data-says-college/)

## How it worked

Students would:

 - Sign in their with @tcd Google account, knowingly accepting only to share email address and Calendar read/write permissions
 - Enter their portal login details (with a link to an [explanation in simple English](https://tcal.rory.ie/about))
 - Enjoy _not_ having to sign in to the portal everyday, navigate to the timetable page, wait 30s+ for the slow DB to respond... before later settling for a screenshot which goes stale any time a class changes. 

<img src="images/setup-mytcd.png" width="369" alt="exam event details in mac calendar">

When exam timetables came out in the Winter of 2016, I built a scraper for that too. This put the exam times, venues, course code, exam number and even [seat number](#Reveal-seat-numbers) into calendar.


<img src="images/exam-event.png" width="270" alt="exam event details in mac calendar">




## Trello Board

I used trello to manage feature ideas/requests and prioritise what to build. I added a purple label to some interesting features I never built.

<img src="images/board-dec-2017.png" width="702" alt="trello board screenshot, December 2017">


## Source code overview

_"Interesting"_ files


- Models/Database
	- [User](app/models/user.rb) Represents a student user of the service. Includes methods for authentication, less trivial state checking and everyone's favourite: `do_the_feckin_thing!` (runs scraper => syncs calendar)
	- [SyncAttempt](app/models/sync_attempt.rb) Logs each scrape, start/end time, number of events changed, error string
	- [QueJob](app/models/que_job.rb) Adding methods to query the current job queue implemented using [Que](https://github.com/chanks/que)
	- [structure.sql](db/structure.sql) Automatically generated file containing the queries/statements to recreate the Postgres setup. Had to switch to the sql file over the usual `schema.rb` to support Que's usage of advanced Postgres features.
- Scrapers
  - [TimetableScraper](app/lib/timetable_scraper.rb) - The spaghetti monster delivering the core functionality! (either blame me OR the obscurity of the MyTCD authentication and template rendering...)
  - [GoogleCalendarSync](app/lib/google_calendar_sync.rb) A far more pleasant class. `sync_events!` takes in a list of gcal events objects. It creates/updates/deletes them using a simple matching procedure on non-primary "Tcal" calendar which it creates pre-sync if not present.
  - [TcdStaffScrape](app/lib/tcd_staff_scrape.rb) Downloads the public directory of staff emails so to give an error notice when signing up. Probably was a bit unnecessary.


If you're interested in how the UI, "setup wizard" etc. worked, check out

- [controllers](app/controllers) HTTP endpoints
- [views](app/views) HTML templates
- [stylesheets](app/assets/stylesheets) Mainly includes small changes to [Semantic UI](https://semantic-ui.com/) (the css framework I used)
- [javascripts](app/assets/javascripts) A sprinkle of front-end _magic!_
- [mailers](app/mailers) Few notifications. The corresponding templates can be found in views




## Misc technical details

### Infra

Initially ran on Azure, then AWS... free credit and that.

Used two instances:

1. Port 80/443 for http open to public traffic running
  - Web App
  - Nginx Server
2. No public internet traffic
  - PostgreSQL database
  - Background worker doing the scraping

```
Azure/AWS ====================|
| [db + worker] <-> [web app] |
|=====vv===============^^^====|
     SITS             users
```
Firewall was setup to let traffic only pass in the direction of the arrows.
Obviously ssh was also available for me to update, configure and do some live debugging. To reach the DB/worker box which accepted no public incoming connections, I connected via the web box.



TODO further development

Something I could have done after

Found people in each course to accept to manage the timetable for their year...
Maybe two or three people could access the calendar, and it's automatically added for everyone else in that year.


sorry for no testing



### Running it:

No need... [really!](https://tcal.rory.ie/ics/)

But sure anyway....


Install Postgres (TODO version), Ruby `2.3.3`

```
create_db tcal_dev
TODO .env file example
rake db:create
rails s
```

<!--
`CREATE EXTENSION IF NOT EXISTS "citext";`-->



#### Reveal seat numbers

1. Go to your exam timetable page on mytcd
2. Bookmark the page
3. Edit the bookmark and change the address/URL to be the code below rather than https://my.tcd.ie/...


```javascript
javascript:(function(){var t=document.getElementsByClassName("sitstablegrid")[1];t.innerHTML=t.innerHTML.replace(/<!---/g, '').replace(/--->/g, '');})()
```

4. Clicking the bookmark when on the exam page will show your seat number beside each exam.


Here's that code expanded:

```
javascript:(
	function() {
		var table = document.getElementsByClassName("sitstablegrid")[1];
		table.innerHTML = table.innerHTML.replace(/<!---/g, '').replace(/--->/g, '');
	}
)()
```
