;****************************************************************************
;Copyright © 2008-2011 Oregon State University
;All Rights Reserved.
;
;
;Permission to use, copy, modify, and distribute this software and its
;documentation for educational, research and non-profit purposes, without
;fee, and without a written agreement is hereby granted, provided that the
;above copyright notice, this paragraph and the following three paragraphs
;appear in all copies.
;
;
;Permission to incorporate this software into commercial products may be
;obtained by contacting Oregon State University Office of Technology Transfer.
;
;
;This software program and documentation are copyrighted by Oregon State
;University. The software program and documentation are supplied "as is",
;without any accompanying services from Oregon State University. OSU does not
;warrant that the operation of the program will be uninterrupted or
;error-free. The end-user understands that the program was developed for
;research purposes and is advised not to rely exclusively on the program for
;any reason.
;
;
;IN NO EVENT SHALL OREGON STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR DIRECT,
;INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST
;PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
;IF OREGON STATE UNIVERSITYHAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
;DAMAGE. OREGON STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
;INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
;FITNESS FOR A PARTICULAR PURPOSE AND ANY STATUTORY WARRANTY OF
;NON-INFRINGEMENT. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS,
;AND OREGON STATE UNIVERSITY HAS NO OBLIGATIONS TO PROVIDE MAINTENANCE,
;SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
;
;****************************************************************************

pro repopulate_image_info, image_info_file, ignore_norms=ignore_norms

  ;assumes that set_up_image_info... has been run
  ;  then it goes through and determines which of the
  ;   subsequent steps have been run (madcalling, cloud-screening, tasselcapping)
  ;   and puts into appropriate places in the image info structure.
  ;  Use if the image info is inadvertantly overwritten

  if n_elements(image_info_file) eq 0 then begin
    print,'Image_info_file does not exist'
    print, image_info_file
    print, 'Please check'
    return
  end
  
  restore, image_info_file
   
  refind = where(image_info.type eq 3, nrefs)
  ;if nrefs ne 1 then message, 'exactly 1 reference image needed, with _refl_cost.img'

  n_files = n_elements(image_info)
  
  print, "repopulating the image_info savefile - please wait..."
  for i = 0, n_files -1 do begin
    thispath = get_pathname(image_info[i].image_file, /unix)
    
    ;check for normalized images "_to_"
    if keyword_set(ignore_norms) eq 1 then goto, start_here
    filebase = strmid(file_basename(image_info[i].image_file),0,18)
    checkfor = filebase+"*_to_*.bsq"
    match = strmatch(image_info[i].image_file, checkfor)   
    if match eq 0 and image_info[i].type ne 3 then begin
      
      matchfiles = file_search(thispath, checkfor, count=n_matchfiles)
      if n_matchfiles ge 1 then begin 		;this means we found a madcal image in the directory
        goods = where(strmatch(matchfiles, "*tc*") ne 1 and strmatch(matchfiles, "*nochange*") ne 1, n_goods)
        if n_goods eq 1 then image_info[i].image_file = matchfiles[goods] else message, "something is wrong"
      endif 
    endif
    
    ;now check to see if this one is a "usearea" image
    ;  built in the "build_use_area_image" program
    
    start_here:
    checkfor = "*USEAREA"
    
    match = strpos(image_info[i].useareafile, checkfor)
    if match eq -1 then begin
      ;the usearea image is not in the image info, so see
      ;  if it is in this year's directory
      l = strlen(image_info[i].image_file)
      matchfiles = file_search(thispath, checkfor)
      if matchfiles[0] ne "" then begin 		;this means we found a cloud mask image in the directory
        n = n_elements(matchfiles)
        
        
        if n gt 1 then begin 	;if more than one file in this folder, match 'em
          ;filename = image_info[i].image_file
        
          filename = file_basename(image_info[i].image_file)
          
          matchpart = strmid(filename,0, 17)
          matchindex = lonarr(n)
          for f = 0, n-1 do matchindex[f] = strpos(file_basename(matchfiles[f]), matchpart)
          goods = where(matchindex ne -1, ngoods)
          if ngoods eq 0 then message, 'tasseled cap image does not match '+image_info[i].image_file
          if ngoods gt 1 then message, 'Two or more usearea images match with '+image_info[i].image_file
          matchfiles = matchfiles[goods]	;just assign the one that matches the full deal
        end
        
        ;put this useareafile in ALL years, since we onlydo one
        image_info.useareafile = matchfiles[0]
       
      end
    end
    
    
    
    ;now check to see if there are cloud and shadow images
    checkfor = "*clddiff.bsq"
    
    
    match = strpos(image_info[i].cloud_diff_file, checkfor)
    
    
    if match eq -1 then begin
      ;the clddiff image is not in the image info, so see
      ;  if it is in the directory
      l = strlen(image_info[i].image_file)
      matchfiles = file_search(thispath, checkfor)
      if matchfiles[0] ne "" then begin 		;this means we found a cloud diff image in the directory
        n = n_elements(matchfiles)
        
        
        if n gt 1 then begin 	;if more than one file in this folder, match 'em
          ; filename = image_info[i].image_file
          filename = file_basename(image_info[i].image_file)
          matchpart = strmid(filename, 0, 17)
          matchindex = lonarr(n)
          for f = 0, n-1 do matchindex[f] = strpos(file_basename(matchfiles[f]), matchpart)
          goods = where(matchindex ne -1, ngoods)
          
          if ngoods gt 1 then message, 'Two or more cloud diff images match with '+image_info[i].image_file
          if ngoods ne 0 then matchfiles = matchfiles[goods] else matchfiles = ''
          
        ;took this out, beceause there are times when we're redoing on file that we don't have a match
        ;if ngoods eq 0 then message, 'Cloud diff image does not match '+image_info[i].image_file
        ;matchfiles = matchfiles[goods]	;just assign the one that matches the full deal
          
        end
        
        ;swap out the original image for the madcalled image
        image_info[i].cloud_diff_file = matchfiles
        image_info[i].cloudyear = 1
        
        
      end
    end
    
    ;now check to see if there are cloud and shadow images
    checkfor = "*shddiff.bsq"
    
    match = strpos(image_info[i].shadow_diff_file, checkfor)
    if match eq -1 then begin
      ;the clddiff image is not in the image info, so see
      ;  if it is in the directory
      l = strlen(image_info[i].image_file)
      matchfiles = file_search(thispath, checkfor)
      if matchfiles[0] ne "" then begin 		;this means we found a cloud diff image in the directory
        n = n_elements(matchfiles)
        
        
        if n gt 1 then begin 	;if more than one file in this folder, match 'em
          ;filename = image_info[i].image_file
          filename = file_basename(image_info[i].image_file)
          
          matchpart = strmid(filename,0, 17)
          matchindex = lonarr(n)
          for f = 0, n-1 do matchindex[f] = strpos(file_basename(matchfiles[f]), matchpart)
          goods = where(matchindex ne -1, ngoods)
          ;if ngoods eq 0 then message, 'Shadow diff image does not match '+image_info[i].image_file
          if ngoods gt 1 then message, 'Two or more shadow diff images match with '+image_info[i].image_file
          
          if ngoods ne 0 then matchfiles = matchfiles[goods] else matchfiles = ''
          
        ; matchfiles = matchfiles[goods]	;just assign the one that matches the full deal
        end
        
        ;swap out the original image for the madcalled image
        image_info[i].shadow_diff_file = matchfiles
        
        
        
      end
    end
    
    ;now check to see if there are cloud mask images
    checkfor = "*cloudmask.bsq"
    
    match = strpos(image_info[i].cloud_file, checkfor)
    if match eq -1 then begin
      ;the clddiff image is not in the image info, so see
      ;  if it is in the directory
      l = strlen(image_info[i].image_file)
      matchfiles = file_search(thispath, checkfor)
      if matchfiles[0] ne "" then begin 		;this means we found a cloud mask image in the directory
        n = n_elements(matchfiles)
        
        
        if n ge 1 then begin 	;if more than one file in this folder, match 'em
          ;filename = image_info[i].image_file
          filename = file_basename(image_info[i].image_file)
          ;filename = get_filename(image_info[i].image_file)
          
          matchpart = strmid(filename, 0, 17)
          matchindex = lonarr(n)
          for f = 0, n-1 do matchindex[f] = strpos(file_basename(matchfiles[f]), matchpart)
          goods = where(matchindex ne -1, ngoods)
          ;if ngoods eq 0 then message, 'cloud mask image does not match '+image_info[i].image_file
          if ngoods gt 1 then message, 'Two or more cloud mask images match with '+image_info[i].image_file
          if ngoods ne 0 then matchfiles = matchfiles[goods] else matchfiles = 'none'
        ;matchfiles = matchfiles[goods]	;just assign the one that matches the full deal
        end
        
        ;swap out the original image for the madcalled image
        image_info[i].cloud_file = matchfiles
        
      end
    end
    
    
    ;now check to see if there are tc images
    checkfor = "*tc.bsq"
    match = strpos(image_info[i].tc_file, checkfor)
    if match eq -1 then begin
      ;the clddiff image is not in the image info, so see
      ;  if it is in the directory
      l = strlen(image_info[i].image_file)
      matchfiles = file_search(thispath, checkfor)  
      if matchfiles[0] ne "" then begin 		;this means we found a cloud mask image in the directory
        n = n_elements(matchfiles)
        filename = file_basename(image_info[i].image_file)
        
        if n gt 1 then begin 	;if more than one file in this folder, match 'em
          ;filename = image_info[i].image_file
        
        
          matchpart = strmid(filename,0, 18)
          print, matchpart
          matchindex = lonarr(n)
          for f = 0, n-1 do matchindex[f] = strpos(file_basename(matchfiles[f]), matchpart)
          goods = where(matchindex ne -1, ngoods)
          ;if ngoods eq 0 then message, 'tasseled cap image does not match '+image_info[i].image_file
          if ngoods gt 1 then message, 'Two or more tasseled cap images match with '+image_info[i].image_file
          
          if ngoods ne 0 then matchfiles = matchfiles[goods] else matchfiles = ''
          
        ;matchfiles = matchfiles[goods]	;just assign the one that matches the full deal
        end
        
        ;swap out the original image for the madcalled image
        matchpart = strmid(filename,0, 18)
        ok= strpos(file_basename(matchfiles), matchpart)
        if ok ne -1 then image_info[i].tc_file = matchfiles    
      end
    end    
  end
  
  a = find_union_area(image_info_file)
  subset = a.coords
  
  for i = 0, n_elements(image_info)-1 do image_info[i].subset = subset
   
  save, image_info, filename = image_info_file
  
  return
end
