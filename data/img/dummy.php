<?php
$n_iter = htmlspecialchars($_GET["n"]);
for ($i = 1; $i <= $n_iter; $i++) {
	if ($i % 4000 == 0) {
		echo $i;
		echo nl2br('\n');
	}
}
?>
