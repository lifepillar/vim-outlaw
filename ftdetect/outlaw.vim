autocmd BufRead,BufNewFile *.outl,*.outlaw setfiletype outlaw
autocmd BufRead,BufNewFile *.taskpaper
      \  setlocal noexpandtab
      \| let b:outlaw_topic_mark='\%(- \|\%(\S\ze[^:]*:\s*\%(\_$\|@\)\)\@=\)'
      \| setfiletype outlaw
