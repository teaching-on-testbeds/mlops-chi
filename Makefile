all: index.md 00_intro.ipynb 01_setup_env_tf.ipynb 02_provision_tf.ipynb 03_setup_env_ansible.ipynb 04_practice_ansible.ipynb 05_deploy_k8s.ipynb 06_post_k8s.ipynb 07_configure_argocd.ipynb 08_lifecycle_part_1.ipynb 09_lifecycle_part_2.ipynb 10_delete.ipynb

clean: 
	rm index.md 0_intro.ipynb 1_setup_env_tf.ipynb 2_provision_tf.ipynb 3_setup_env_ansible.ipynb 4_practice_ansible.ipynb 5_deploy_k8s.ipynb 6_post_k8s.ipynb 7_configure_argocd.ipynb 8_lifecycle_part_1.ipynb 9_lifecycle_part_2.ipynb 00_intro.ipynb 01_setup_env_tf.ipynb 02_provision_tf.ipynb 03_setup_env_ansible.ipynb 04_practice_ansible.ipynb 05_deploy_k8s.ipynb 06_post_k8s.ipynb 07_configure_argocd.ipynb 08_lifecycle_part_1.ipynb 09_lifecycle_part_2.ipynb 10_delete.ipynb

index.md: snippets/*.md images/*
	cat snippets/intro.md \
		snippets/setup_env_tf.md \
		snippets/provision_tf.md \
		snippets/setup_env_ansible.md \
		snippets/practice_ansible.md \
		snippets/deploy_k8s.md \
		snippets/post_k8s.md \
		snippets/configure_argocd.md \
		snippets/lifecycle_part_1.md \
		snippets/lifecycle_part_2.md \
		snippets/delete.md \
		> index.tmp.md
	grep -v '^:::' index.tmp.md > index.md
	rm index.tmp.md
	cat snippets/footer.md >> index.md

00_intro.ipynb: snippets/intro.md
	pandoc --resource-path=../ --embed-resources --standalone --wrap=none \
				-i snippets/frontmatter_python.md snippets/intro.md \
				-o 00_intro.ipynb  
	sed -i 's/attachment://g' 00_intro.ipynb

01_setup_env_tf.ipynb: snippets/setup_env_tf.md
	pandoc --resource-path=../ --embed-resources --standalone --wrap=none \
				-i snippets/frontmatter_bash.md snippets/setup_env_tf.md \
				-o 01_setup_env_tf.ipynb  
	sed -i 's/attachment://g' 01_setup_env_tf.ipynb

02_provision_tf.ipynb: snippets/provision_tf.md
	pandoc --resource-path=../ --embed-resources --standalone --wrap=none \
                -i snippets/frontmatter_bash.md snippets/provision_tf.md \
				-o 02_provision_tf.ipynb  
	sed -i 's/attachment://g' 02_provision_tf.ipynb

03_setup_env_ansible.ipynb: snippets/setup_env_ansible.md
	pandoc --resource-path=../ --embed-resources --standalone --wrap=none \
				-i snippets/frontmatter_bash.md snippets/setup_env_ansible.md \
				-o 03_setup_env_ansible.ipynb  
	sed -i 's/attachment://g' 03_setup_env_ansible.ipynb

04_practice_ansible.ipynb: snippets/practice_ansible.md
	pandoc --resource-path=../ --embed-resources --standalone --wrap=none \
                -i snippets/frontmatter_bash.md snippets/practice_ansible.md \
				-o 04_practice_ansible.ipynb  
	sed -i 's/attachment://g' 04_practice_ansible.ipynb

05_deploy_k8s.ipynb: snippets/deploy_k8s.md
	pandoc --resource-path=../ --embed-resources --standalone --wrap=none \
                -i snippets/frontmatter_bash.md snippets/deploy_k8s.md \
				-o 05_deploy_k8s.ipynb  
	sed -i 's/attachment://g' 05_deploy_k8s.ipynb

06_post_k8s.ipynb: snippets/post_k8s.md
	pandoc --resource-path=../ --embed-resources --standalone --wrap=none \
                -i snippets/frontmatter_bash.md snippets/post_k8s.md \
				-o 06_post_k8s.ipynb  
	sed -i 's/attachment://g' 06_post_k8s.ipynb

07_configure_argocd.ipynb: snippets/configure_argocd.md
	pandoc --resource-path=../ --embed-resources --standalone --wrap=none \
				-i snippets/frontmatter_bash.md snippets/configure_argocd.md \
				-o 07_configure_argocd.ipynb  
	sed -i 's/attachment://g' 07_configure_argocd.ipynb

08_lifecycle_part_1.ipynb: snippets/lifecycle_part_1.md
	pandoc --resource-path=../ --embed-resources --standalone --wrap=none \
				-i snippets/frontmatter_python.md snippets/lifecycle_part_1.md \
				-o 08_lifecycle_part_1.ipynb  
	sed -i 's/attachment://g' 08_lifecycle_part_1.ipynb

09_lifecycle_part_2.ipynb: snippets/lifecycle_part_2.md
	pandoc --resource-path=../ --embed-resources --standalone --wrap=none \
				-i snippets/frontmatter_python.md snippets/lifecycle_part_2.md \
				-o 09_lifecycle_part_2.ipynb  
	sed -i 's/attachment://g' 09_lifecycle_part_2.ipynb

10_delete.ipynb: snippets/delete.md
	pandoc --resource-path=../ --embed-resources --standalone --wrap=none \
				-i snippets/frontmatter_bash.md snippets/delete.md \
				-o 10_delete.ipynb  
	sed -i 's/attachment://g' 10_delete.ipynb
