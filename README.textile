OpenAPI is an HTTP API generator, which allows you to expose a MySQL database 
for open query safely and securely. It features timeouts and cost analysis
features, with integrated pagination and advanced query functionality, which 
gives developers flexibile read-only access.

Installation
==========================

Download or clone the repository, then extract the contents if necessary. 
After changing into the directory containing OpenAPI, make sure you've 
installed Bundler: 

    $ gem install bundler

and then install all the necessary application dependencies:

    $ bundle install

Configuration
==========================

The config.yml file contains the settings OpenAPI needs to access your
database, as well as the main configuration for how you want to expose your
database to the world.

Name
--------------------------

The name parameter should contain the name of your API. It is used in the 
documentation generator as part of the header.


Database
--------------------------

The database access is configured via ActiveRecod, so this block will be 
familiar to Rails developers. All settings are required:

  database:
    adapter: mysql2
    host: localhost
    database: mydb
    username: user
    password: 1234

Options
--------------------------

  timeout: 30
  perpage: 500
  maxcost: 50000


*timeout* - The number of seconds before a query request should time out.
*perpage* - The number of results to return per page. Since no supporting
  HTML is displayed, you should feel comfortable setting this value to
  something a bit higher than you would for your web page.
*maxcost* - The number of rows a query will iterate over before it's 
  assumed to large to execute. The cost is calculated by taking the sum 
  of the 'rows' column of a MySQL EXPLAIN query.

Tables
--------------------------

tables:
  mytablename:
    doc: "A description of the table used by the documentation generator"
    mycolumn: "Some description of my column used by the documentation generator"
    require:
      - mytablename.status eq "published"

  mysecondtable:
    doc: "Second table"
    mycolumn2: "A colum in the second table."


The `tables` setting provides the mechanims you use to map the query columns
to the columns in the database OpenAPI will expose. All columns exposed must
be explicitly configured here - otherwise they will not be returned.

Use the `doc` attribute in your table configuration to provide a description
of the table for use in the automatically generated documentation. String
values associated with each column will be used to further define those columns
in this documentation.

If you have data that should not be displayed, you can use the `require`
setting to add conditions that are applied to every query. In the above example,
no records from mytablename will be returned unless the status column contains
a value of 'published'.

See the automatically generated documentation for more information regarding
conditions syntax.


Running the Server
==========================

You can run Sinatra directly from the command line if you're just debugging
a configuration file:

    $ ruby open-api.rb

But if you're looking to deploy into production, please examine the Sinatra
deployment documentation at http://sinatra-book.gittr.com/#deployment


Usage
==========================

Once the OpenAPI server is running, visit `/doc` in your web browser, using
the server information you've deployed with. If you're running from the 
development mode, visit http://localhost:4567/doc. This will contain all the
information necessary to access the API.

Caveats + Notes
==========================

* No methods for applying transformations to exposed data. This means file
path data or anything else generally manipulated in the software accessing
the database will not be easily available. Suggestions for how best to add
basic transformative callbacks are welcome!

* Field parsing not available for dates, binary, etc. It's on the TODO list.
