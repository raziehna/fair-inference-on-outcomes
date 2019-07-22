
# Fair Inference On Outcomes

This is an implementation of the following paper: 

[Fair Inference On Outcomes](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&ved=2ahUKEwjP86OOucfjAhUOy1kKHVLEAOgQFjABegQIBBAC&url=https%3A%2F%2Fwww.aaai.org%2Focs%2Findex.php%2FAAAI%2FAAAI18%2Fpaper%2Fdownload%2F16683%2F15898&usg=AOvVaw1WJUX88iZwZ_Flgw6Czisa)
(AAAI, 2018)


If you find it useful, please consider citing:
```
@inproceedings{nabi18fair,
title = {Fair Inference on Outcomes},
author = { Razieh Nabi and Ilya Shpitser},
booktitle = {Proceedings of the Thirty Second Conference on Association for the Advancement of Artificial Intelligence (AAAI-32nd)},
year = { 2018 }, 
publisher = { AAAI Press }
}
```


## Abstract  
In this paper, we consider the problem of fair statistical in- ference involving outcome variables. Examples include classification and regression problems, and estimating treatment effects in randomized trials or observational data. The issue of fairness arises in such problems where some covariates or treatments are “sensitive,” in the sense of having potential of creating discrimination. In this paper, we argue that the presence of discrimination can be formalized in a sensible way as the presence of an effect of a sensitive covariate on the outcome along certain causal pathways, a view which gener- alizes (Pearl 2009). A fair outcome model can then be learned by solving a constrained optimization problem. We discuss a number of complications that arise in classical statistical in- ference due to this view and provide workarounds based on recent work in causal and semi-parametric inference.


## Brief Overview 
With the massive expansion of available data and advancements in machine learning (ML) algorithms, increasingly important decisions are being automated. Unfortunately, this increases the potential for discriminatory biases to become “baked in” to automated systems that influence people’s lives. Without careful adjustments for these biases during learning and deployment of automated systems, these systems could indeed put certain individuals at risk of discrimination. Concerns among policymakers and regulators on the potentially harmful impact of deploying discriminatory learning systems, lead to an urgent call for researchers to devise a sensible framework for modeling discrimination, and enabling fair statistical inference. Here, we consider discrimination with respect to a sensitive feature, such as race, gender, or religion, that arises in inference problems involving outcome variables, such as classification problems.

Naive repairs for discriminatory practices in statistical inference do not work. As an example, Northpointe has developed a risk assessment tool, named COMPAS, that scores offenders based on a questionnaire, socioeconomic, and criminal history information, while ignoring sensitive features like race [2]. This tool is already being used within the legal system in certain areas of the United States to influence parole and sentencing decisions. Unfortunately, this approach does not guarantee fairness due to the presence of proxies of the sensitive feature that are correlated with the outcome, such as residence area code. A common class of approaches for fair inference defines discrimination as a type of associative relationship between the sensitive feature and the outcome. For instance, [3] has proposed a fairness criterion, called equalized odds, that ensures that the true and false positive rates are equal across all groups. This criterion was inspired by a White House report on “equal opportunity by design” [4]. Any approach that relies on associative measures of association will do an intuitively wrong thing in scenarios where the sensitive feature is not randomly assigned, like gender, but instead exhibits spurious correlations with the outcome through other possibly unobserved features. An example of such a feature is prior conviction status (certain types of decisions, such as hiring, forbid discrimination on this feature).

Even in cases where the sensitive feature is randomized, seemingly sensible definitions tend to be overly restrictive. Consider the hiring example where potential discrimination is with respect to gender (a variable that is randomized at birth). It makes intuitive sense to say that job applicants’ gender should not directly influence the hiring decision, but may influence the hiring decision indirectly, via secondary applicant characteristics important for the job, and correlated with gender. In this example, discrimination intuitively corresponds to a part of the causal relationship between gender and the hiring decision.

In discussing the extent to which a particular approach is “fair” we believe the gold standard is human intuition. Inspired by provided examples and informal definitions which appeared in the legal and causal inference literature [5, 1], we propose that discrimination ought to be formalized as the presence of certain path-specific effects (PSEs) [6, 7]. The specific paths which correspond to discrimination are a domain specific issue. For example, a path from gender to the result of a physical test to hiring may be appropriate for a fire department, but inappropriate for an accounting firm.


To represent discrimination formally, we assume the observed data distribution p(Y, X), is induced by a causal model, and the PSE is identified as a functional f(p(Y,X)). Finally, we fix upper and lower bounds εl , εu on the PSE, representing the degree of discrimination we are willing to tolerate. Our proposal is to transform the inference problem on p(Y, X), the “unfair” world, into an inference problem on another distribution p∗(Y, X), the “fair” world, which is close, in the KL-divergence sense, to p(Y,X) while also having the property that the PSE lies within (εl,εu). Given a finite dataset D drawn from p(Y, X), a likelihood function L(D; α), an estimator g(D) of the PSE, and εl , εu , we approximate p∗ by solving the following constrained maximum likelihood problem:


<p align="center">
<img width="218" alt="Screenshot 2019-07-21 22 47 12" src="https://user-images.githubusercontent.com/19523408/61602932-9110ef00-ac09-11e9-9bf7-77fbcdc18e12.png">
</p>


Crucial to our proposal, statistical inference on previously unseen instances cannot be carried out until instances are mapped onto the fair world p∗. This is because unseen instances will generally be drawn from p, rather than p∗. We propose a simple conservative approach for doing so, although others are possible. Had we known p and p∗ exactly, predicting Y given α , and a new data point xi entails using only a subset of the values xiW where W is the largest subset of X where p(W) = p∗(W), assuming W is non-empty. Since we don’t know p and p∗, the set W depends on what parts of p(Y, X) are constrained, and this depends on the estimator g.



In situations where the PSE is not identifiable, we suggest three classes of approaches: more assumptions that yield identification, if they are sensible, inclusion of additional paths that renders the PSE identified (but at the cost of including “fair” paths in our measure of discrimination), or relying on non-parametric bounds for the non-identified PSE [8]. In cases where we wish to regularize the outcome prediction model, we use tools from semi-parametric inference to give estimators g(.) which yield consistent estimates of the PSE regardless of the chosen outcome model.


We illustrate our approach to fair inference via the COMPAS dataset [2] where we are interested in predicting risk of recidivism among African-Americans and Caucasians. Data includes race denoted by A, prior convictions as the mediator denoted by M, demographic information such as age and gender collected in C, and recidivism indicator Y . We define discrimination via the direct path from race to recidivism. The effect along this path is called natural direct effect (NDE) [9, 6]. We obtained the posterior sample representation of E[Y |A, M, C] via both regular and constrained BART [10]. Under the unconstrained posterior, the NDE (on the odds ratio scale) was equal to 1.3, which implies that the odds of recidivism would have been 1.3 times higher if we hypothetically would have changed the race from Caucasian to African-American. Using unconstrained BART, our prediction accuracy on the test set was 67.8%, removing treatment from the outcome model dropped the accuracy to 64.0%, while using constrained BART lead to the accuracy of 66.4%. As expected, dropping an informative feature led to greater decrease in accuracy, compared to simply constraining the outcome model to obey the constraint on the NDE. Our approach, by definition, cannot do better than classifiers based on the full maximum likelihood estimator, since such an estimator uses data as well as possible under correctly specified models. The idea behind our proposal is to use the data as well as possible while also remaining fair.


One of the advantages of our approach is it can be readily extended to concepts like affirmative action and “the wage gap” in a way that matches human intuition. One methodological difficulty with our approach is the need for a computationally challenging constrained optimization problem. An alternative is to think about reparameterizing the observed data likelihood in terms of causal parameter for an arbitrary PSE (which is currently an open problem).


## References 

[1] Judea Pearl. Causality: Models, Reasoning, and Inference. Cambridge University Press, 2 edition, 2009.

[2] J. Angwin, J. Larson, S. Mattu, and L. Kirchner. Machine bias. https://www.propublica.org/criminal-
sentencing, 2016.

[3] Moritz Hardt, Eric Price, and Nati Srebro. Equality of opportunity in supervised learning. In Advances In
Neural Information Processing Systems, pages 3315 – 3323, 2016.

[4] Big data: A report on algorithmic systems, opportunity, and civil rights, May 2016.

[5] 7th Circuit Court. Carson vs Bethlehem Steel Corp., 1996. 70 FEP cases 921.

[6] Judea Pearl. Direct and indirect effects. In Proceedings of the Seventeenth Conference on Uncertainty in Artificial Intelligence (UAI-01), pages 411–420. Morgan Kaufmann, San Francisco, 2001.

[7] Chen Avin, Ilya Shpitser, and Judea Pearl. Identifiability of path-specific effects. In Proceedings of the Nineteenth International Joint Conference on Artificial Intelligence (IJCAI-05), volume 19, pages 357–363. Morgan Kaufmann, San Francisco, 2005.

[8] Caleb Miles, Phyllis Kanki, Seema Meloni, and Eric Tchetgen Tchetgen. On partial identification of the pure direct effect. Journal of Causal Inference, 2016.

[9] James M. Robins and Sander Greenland. Identifiability and exchangeability of direct and indirect effects. Epidemiology, 3:143–155, 1992.

[10] Hugh A. Chipman, Edward I. George, and Robert E. McCulloch. BART: Bayesian additive regression trees. Annals of Applied Statistics, 4(1):266–298, 2010.



## License
[MIT](https://choosealicense.com/licenses/mit/)
