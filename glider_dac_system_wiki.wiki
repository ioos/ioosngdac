# GliderDAC

Project number 209378
GliderDAC 2021

# Basic information ==

# Stability concerns ==

* Load averages in general
* Memory usage
* Disk space
* [[QARTOD]] - need to port to new process

## General data flow.

### flow of NetCDF data

# TODO: add details for /home/glider/full_sync, other cron job scripts on glider user
Data is first sent to the Glider DAC FTP server, which is run using vsftpd.
The server is set up to have authentication take place using a BerkeleyDB PAM
module, which determines the user.  Upon successful authentication via FTP,
the user is put in the starting directory `/data/submission/${virtual_user}`.

An rsync job is run periodically from `/etc/crontab`, namely the script 
`/opt/scripts/sync_deployments.py`.  This script syncs the contents of
`/data/submission` to `/data/data/priv_erddap`.  This latter folder is where
the data is ultimately generated.  Since the `--delete` flag is passed and
`/data/submission` and `/data/` constitute separate mount points, care should
taken not to unmount the submission folder, as it will cause files to be deleted.
In any event, backups are available on S3 (where?)

`replicatePrivateErddapDeployments.py` makes requests to the "private" ERDDAP
aggregates copies over data files into a single file into currently only 
/data/data/pub_erddap`.  There is no "public ERDDAP" application running anymore,
but the generated files are used for archival.  The THREDDS instance could possibly
have aggregations resumed, but we'd like to retire THREDDS at some point, so
a balance has to be struck.  Also, in either case, ERDDAP seems to be using
some kind of 32-bit integer, which can cause the files not to be properly
aggregated if they are over ~ 2.14 GB when aggregated.  Bob Simons, the creator
of ERDDAP, is aware of these limitations and says the limit might be lifted
once he goes to 64-bit integers, which are considerably larger.  In practice,
this issue sometimes shows up in 

## ERDDAP datasets.xml

buildErddapDatsetsCatalog.py

Builds the ERDDAP catalog.  Non-completed real-time dataset are set to update
more frequently, whereas completed real-time and delayed mode (assumed to have all data uploaded)
are less often.

There exists a mechanism in which one can place extra attributes they'd like to see in the JSON file inside a file
named extra_atts.json

The files themselves are updated via a watchdog script which looks for new or moved files in the /data/data/priv_erddap folder
using bindings to inotify events.  When a file event of the appropriate types is detected, an empty file with the deployment name
is placed in the /scratch/tomcat-erddap-private/flag folder.
If new files aren't syncing to ERDDAP (see below), check that this container is running.
It may be worthwhile to restart the container in the event that modifications aren't picked up.

Catalog snippets are cached unless the `--force`/`-f` flag is given.  These
cached snippets are not regenerated unless 

## Monitoring

gliders.ioos.us/monitoring has telegraf dashboards for system/proc usage stats.

Also available is a dashboard which shows the update times of files relative to what is stored on ERDDAP.
This dashboard will alert after a certain threshold (how long?) and can often help diagnose when data flow is improper.

## Resizing filesystems

Occasionally, filesystems will fill up.  Use `sudo ncdu -x <MOUNTPOINT>` to see
where FS contents are taking up most space.  From there, if additional resizing
is needed, first resize the AWS EBS volume through the AWS console or via the
CLI tools.  Use `growpart` if it is a partition, and then choose the appropriate tool
depending on whether XFS or ext4 (`xfs_growfs` and `e2resizefs`, respectively).
The `/data/submission/` mount uses LVM -- consult changelog.txt for additional
directions.

## Near-real time updates of datasets

## QARTOD/QC


EDIT: QARTOD now running as of around 2022-01-14.  Files are marked with
Linux xattrs of "user.qc_run=true" when QC has been run.  This is susbstantially
faster than opening netCDF files to do this, but still has to check O(n) files.
Also, the scripts are utilizing
an older version of the QARTOD library, "ioos/qartod", instead of the new,
Python 3 compatible version "IOOS QARTOD".  Perhaps use serverless/lambdas?

Care should be taken not to overwrite the existing scripts.


# Databases used

## MongoDB

MongoDB is used to store various metadata about deployments and stations.
There are only three collections, which are self-explanatorily named:
- users
- deployments
- institutions

## BerkeleyDB

BerkeleyDB is used as a PAM auth provider for the FTP server, as well as serving
to authenticate users when a password is stored.  An important note here is that
despite the fact that most user information is stored in the database, password
information is not.

## Status page

The status page pulls from either the providers API or a static status.json file
generated from these contents.  The API itself is populated by a call to the

## Glider Check emails/compliance checker

There are currently hooks for compliance checker to be run upon completion
of the dataset.  This process at one point had sent email and would stop
archival of the dataset, but it was found to be too stringent.
Compliance checks have been updated to only check for valid CF standard
names prior to archival


## Archival

Archival is done via the `/home/glider/ncei_archive.sh` script.  Deployments that are desired to be archived must be marked as completed and the
option "Submit to NCEI on completion"
The script copies files placed in `/data/data/pub_erddap/` subdirectories created by
`replicatePrivateErddapDeployments.py` into `/data/data/archive`.  If files
corresponding to the deployment name exist with a file extension of
`.DO-NOT-ARCHIVE`, the archival process is passed over for that particular deployment.


## Current differences between development and production servers

Ideally, dev and production would more or less mirror one another in terms
of setup.  In practice, this is not the case.  Several changes exist between
dev and production servers:

As of 2021-06-28:


## Notes on admin user

Admin users are defined in the config.yml, *not* in the database!  Look for the
key `ADMINS` in the `config.local.yml` file.

## Creating a new user

To create a new user, become an admin user and add an account

### Changing password on a user

If you are logged in as a user or are an admin, you may change the password
for that user.  Note that if you are a non-admin user, it is possible to reset
your password without the use of a confirmation email, which goes against OWASP
best practices


## Glider Plots

Glider plots are generated by the status application.  Plots that need to be
generated are determined by iterating over the status.json file generated
from the database contents.  Down the road, this could probably be moved to
the Swagger API or by database calls themselves instead of having to rely on
the JSON file.  The call the looks for any deployments updated within the last
three days (variable is called `one_week`, but it only has three days), or
with an end time that was within the last week.  The _THREDDS_ OPeNDAP URL
is then provided and the name URL is placed in a message body which is uploaded
to an SQS queue.  Somehow, processing is picked up by a Lambda function which
consumes from the SQS queue.  The function name is
`deployment-ts-profile-plots`.  Lambda event triggers, SQS Lambda invocations,
and CloudWatch Events were checked but did not turn up any indication of how
the Lambda function is called.

EDIT: Profile plot generation is running under ECS, not Lambda.

## Compliance Checking

The IOOS Compliance Checker is run against completed deployments.  Currently,
only valid standard names are checked under the CF compliance checker.  If any
names are detected as invalid, the dataset will be prevented from being archived at NCEI

## Modifying dataset aggregation attributes with JSON

A file named `extra_atts.json` may be included in a deployment directory to
modify metadata.  The top level keys are used to refer to variables, with the exception
of the `_global_attrs` key, which changes dataset global attributes.

Here is an example where the global attribute `institution` has been changed,
along with the attributes `valid_min` and `valid_max` in the variable `longitude`:


```json
{
  "_global_attrs": {
    "institution": "Oregon State University"
  },
  "longitude": {
    "valid_min": -180,
    "valid_max": 180
  }
}
```


TODO: Add functionality in Gliders Providers app to allow providers to modify metadata.  Determine suitable representation in database for this functionality.

