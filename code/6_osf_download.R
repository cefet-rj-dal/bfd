#instructions for download osf files
#https://api.osf.io/v2/nodes/8eh3p/files/osfstorage/

#2001 dataset

library(osfr)

# projeto do brazilian flights dataset
cr_project <- osf_retrieve_node("8eh3p")

lst <- osf_ls_files(cr_project, n_max = Inf)

# first file
item <- lst$meta[[1]]

#filename
print(item$attributes$name)

#url for the filename
urlfile <- url(item$links$download)
printf(urlfile)
load(urlfile)